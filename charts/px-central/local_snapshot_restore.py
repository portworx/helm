#!/usr/bin/env python3
import json
import sys
import subprocess
import time
import logging

# --------------------------------------------------------------------------------
# Configure logging
# --------------------------------------------------------------------------------
logging.basicConfig(level=logging.INFO, format="%(asctime)s - %(levelname)s - %(message)s")
logger = logging.getLogger(__name__)

# --------------------------------------------------------------------------------
# Custom exception for pxctl command errors
# --------------------------------------------------------------------------------
class PxctlCommandError(Exception):
    """Raised when a pxctl command fails, times out, or hits another exception."""
    def __init__(self, cmd, returncode, stderr):
        super().__init__(f"Command failed (exit code={returncode}): {' '.join(cmd)}\n{stderr}")
        self.cmd = cmd
        self.returncode = returncode
        self.stderr = stderr

# --------------------------------------------------------------------------------
# Function: run_cmd
#   - Returns stdout if success
#   - Raises PxctlCommandError if failure, timeout, or other exception
# --------------------------------------------------------------------------------
def run_cmd(cmd, timeout=60):
    logger.debug(f"Running command: {' '.join(cmd)}")
    try:
        result = subprocess.run(cmd, capture_output=True, text=True, timeout=timeout)
        result.check_returncode()  # Raises CalledProcessError if return code != 0
        return result.stdout.strip()
    except subprocess.TimeoutExpired:
        raise PxctlCommandError(cmd, 1, "Timeout expired")
    except subprocess.CalledProcessError as e:
        raise PxctlCommandError(cmd, e.returncode, e.stderr.strip())
    except Exception as e:
        raise PxctlCommandError(cmd, 1, str(e))

# --------------------------------------------------------------------------------
# Helper functions that call run_cmd
# --------------------------------------------------------------------------------

def get_volume_info_json(volume_name_or_id):
    """
    Returns the JSON info for a volume by name or ID using `/opt/pwx/bin/pxctl v i --json`.
    If multiple volumes are returned, returns the first one in the list.
    """
    if not volume_name_or_id:
        logger.warning("get_volume_info_json called with empty volume_name_or_id.")
        return None

    cmd = ["/opt/pwx/bin/pxctl", "v", "i", str(volume_name_or_id), "--json"]
    try:
        stdout = run_cmd(cmd)
        if not stdout:
            logger.warning(f"No output from pxctl for volume {volume_name_or_id}")
            return None
        vol_info = json.loads(stdout)
        # If the result is a list, return the first element
        if isinstance(vol_info, list):
            return vol_info[0] if vol_info else None
        return vol_info
    except PxctlCommandError as e:
        logger.warning(f"Failed to get volume info for {volume_name_or_id}: {e.stderr}")
        return None
    except json.JSONDecodeError:
        logger.warning(f"Unable to decode JSON output for volume {volume_name_or_id}")
        return None

def get_snapshot_nodes(snapshot_id):
    """
    Returns a set of node IDs (or node names) where the snapshot is present.
    Uses `/opt/pwx/bin/pxctl v l -s -j` to list snapshots in JSON, then tries
    to locate the snapshot by its ID, and extract `replica_sets[].nodes[]`.
    """
    if not snapshot_id:
        logger.warning("get_snapshot_nodes called with empty snapshot_id.")
        return set()

    cmd = ["/opt/pwx/bin/pxctl", "v", "l", "-s", "-j"]
    try:
        stdout = run_cmd(cmd)
        if not stdout:
            logger.warning("No snapshot data returned by pxctl.")
            return set()

        snapshots = json.loads(stdout)
        if not isinstance(snapshots, list):
            logger.warning("Snapshot listing JSON did not return a list.")
            return set()

        snapshot_nodes = set()
        for snap in snapshots:
            if not isinstance(snap, dict):
                continue
            snap_id = snap.get("id", "")
            if str(snapshot_id) in snap_id:
                # Found a matching snapshot
                replica_sets = snap.get("replica_sets", [])
                if isinstance(replica_sets, list):
                    for rs in replica_sets:
                        if not isinstance(rs, dict):
                            continue
                        nodes = rs.get("nodes", [])
                        if isinstance(nodes, list):
                            snapshot_nodes.update(nodes)
                else:
                    logger.warning("replica_sets is not a list in snapshot data.")
        return snapshot_nodes

    except PxctlCommandError as e:
        logger.warning(f"Failed to list snapshots: {e.stderr}")
        return set()
    except json.JSONDecodeError:
        logger.warning("Unable to decode JSON output from snapshot listing.")
        return set()

def get_volume_nodes(volume_name_or_id):
    """
    Returns a set of node IDs where the volume has replicas, based on
    `replica_sets[].nodes` from `/opt/pwx/bin/pxctl v i <volume> -j`.
    """
    vol_info = get_volume_info_json(volume_name_or_id)
    if not vol_info:
        return set()

    replica_sets = vol_info.get("replica_sets", [])
    if not isinstance(replica_sets, list):
        logger.warning("replica_sets is not a list in volume info.")
        return set()

    volume_nodes = set()
    for rs in replica_sets:
        if not isinstance(rs, dict):
            continue
        nodes = rs.get("nodes", [])
        if isinstance(nodes, list):
            volume_nodes.update(nodes)
        else:
            logger.warning("nodes is not a list in replica set data.")
    return volume_nodes

def get_volume_ha(volume_name_or_id):
    """
    Returns the HA level of the volume by reading `spec.ha_level` from JSON.
    """
    vol_info = get_volume_info_json(volume_name_or_id)
    if vol_info is None:
        return None

    spec = vol_info.get("spec")
    if not isinstance(spec, dict):
        logger.warning("Volume info 'spec' is not a dictionary.")
        return None

    ha_value_str = spec.get("ha_level")
    if ha_value_str and str(ha_value_str).isdigit():
        return int(ha_value_str)
    else:
        logger.warning(f"HA level not found or invalid for volume {volume_name_or_id}")
        return None

# --------------------------------------------------------------------------------
# Structured error handling in place for volume updates / restore
# --------------------------------------------------------------------------------

class VolumeUpdateError(Exception):
    """Custom exception for update-volume operations."""

def update_volume_ha_excluding_node(volume_id, target_ha, node_to_remove):
    """
    Attempt to scale the volume to 'target_ha' by removing 'node_to_remove'.
    Raises VolumeUpdateError on failure.
    """
    if not volume_id or not node_to_remove:
        raise VolumeUpdateError("update_volume_ha_excluding_node called with invalid arguments.")

    cmd = [
        "/opt/pwx/bin/pxctl", "v", "u",
        "--repl", str(target_ha),
        str(volume_id),
        "--node", str(node_to_remove)
    ]
    logger.info(f"Scaling volume {volume_id} to HA={target_ha}, removing node={node_to_remove}")
    try:
        _ = run_cmd(cmd)  # We don't necessarily need the stdout for further logic
    except PxctlCommandError as e:
        logger.error(f"Failed to remove node {node_to_remove} (HA -> {target_ha}) for volume {volume_id}: {e.stderr}")
        raise VolumeUpdateError(f"Failed update_volume_ha_excluding_node: {e.stderr}")

def update_volume_ha_no_node(volume_id, target_ha):
    """
    Scale the volume to 'target_ha' without specifying a node.
    Raises VolumeUpdateError on failure.
    """
    if not volume_id:
        raise VolumeUpdateError("update_volume_ha_no_node called with empty volume_id.")

    cmd = [
        "/opt/pwx/bin/pxctl", "v", "u",
        "--repl", str(target_ha),
        str(volume_id)
    ]
    logger.info(f"Scaling volume {volume_id} to HA={target_ha} (PX will pick the node).")
    try:
        _ = run_cmd(cmd)
    except PxctlCommandError as e:
        logger.error(f"Failed to scale volume {volume_id} to HA={target_ha}: {e.stderr}")
        raise VolumeUpdateError(f"Failed update_volume_ha_no_node: {e.stderr}")

def reduce_volume_ha_stepwise_excluding_snapshot(volume_id, start_ha, end_ha, snapshot_id):
    """
    Move HA level from start_ha to end_ha one step at a time.
    When SCALING DOWN, *avoid removing the snapshot node* if possible.
    Raises VolumeUpdateError if something goes wrong.
    """
    if not volume_id or not snapshot_id:
        raise VolumeUpdateError("reduce_volume_ha_stepwise_excluding_snapshot called with invalid arguments.")

    if not isinstance(start_ha, int) or not isinstance(end_ha, int):
        raise VolumeUpdateError("start_ha/end_ha must be integers.")

    step = 1 if end_ha > start_ha else -1
    current_ha = start_ha

    while current_ha != end_ha:
        next_ha = current_ha + step

        current_volume_nodes = get_volume_nodes(volume_id)
        current_snapshot_nodes = get_snapshot_nodes(snapshot_id)

        if not current_volume_nodes:
            logger.error(f"No volume nodes found for volume {volume_id}. Cannot scale from {current_ha} to {next_ha}.")
            return

        if step < 0:
            # SCALING DOWN: remove a replica
            candidates_to_remove = (current_volume_nodes - current_snapshot_nodes) or current_volume_nodes
            if not candidates_to_remove:
                raise VolumeUpdateError(
                    f"No valid candidate to remove for scaling down from HA={current_ha} to {next_ha}."
                )

            node_to_remove = list(candidates_to_remove)[0]
            logger.info(f"Scaling down from HA={current_ha} to HA={next_ha}, removing node: {node_to_remove}")
            try:
                update_volume_ha_excluding_node(volume_id, next_ha, node_to_remove)
            except VolumeUpdateError as e:
                raise VolumeUpdateError(
                    f"Failed to remove node {node_to_remove} (HA {current_ha} -> {next_ha}). Reason: {str(e)}"
                )
        else:
            # SCALING UP: add a replica
            logger.info(f"Scaling up from HA={current_ha} to HA={next_ha}.")
            try:
                update_volume_ha_no_node(volume_id, next_ha)
            except VolumeUpdateError as e:
                raise VolumeUpdateError(
                    f"Failed to scale up from HA={current_ha} to {next_ha} for {volume_id}. Reason: {str(e)}"
                )

        time.sleep(2)
        current_ha = next_ha

class VolumeRestoreError(Exception):
    """Custom exception for volume restore operation."""

def restore_volume(volume_name, snapshot_id):
    """
    Run the /opt/pwx/bin/pxctl v restore command to restore volume_name from snapshot_id.
    Raises VolumeRestoreError on failure.
    """
    if not volume_name or not snapshot_id:
        raise VolumeRestoreError("restore_volume called with empty volume_name or snapshot_id.")

    cmd = ["/opt/pwx/bin/pxctl", "v", "restore", volume_name, "-s", str(snapshot_id)]
    logger.info(f"Restoring volume={volume_name} from snapshot={snapshot_id}")
    try:
        stdout = run_cmd(cmd)
        logger.info(f"Successfully restored volume {volume_name} from snapshot {snapshot_id}")
        logger.debug(f"Restore command output: {stdout}")
    except PxctlCommandError as e:
        logger.error(f"Failed to restore volume {volume_name}: {e.stderr}")
        raise VolumeRestoreError(f"Failed to restore volume {volume_name}: {e.stderr}")

# --------------------------------------------------------------------------------
# Main logic
# --------------------------------------------------------------------------------

def process_volume(volume_obj):
    """
    Given a single volume object (including name, backup_id, etc.):
      1) parse snapshot id,
      2) check HA, scale down if needed,
      3) restore,
      4) scale back up if needed.
    Uses structured error handling with exceptions.
    """
    if not isinstance(volume_obj, dict):
        logger.warning("process_volume called with invalid volume_obj (not a dict).")
        return

    backup_id = volume_obj.get("backup_id", "")
    volume_name = volume_obj.get("name", "")
    if not backup_id or not volume_name:
        logger.warning(f"Skipping volume: missing backup_id or name in {volume_obj}")
        return

    snapshot_id = backup_id.split('-')[-1]
    if not snapshot_id:
        logger.warning(f"Skipping volume {volume_name}: backup_id has no '-' or snapshot_id is empty.")
        return

    original_ha_value = get_volume_ha(volume_name)
    if original_ha_value is None:
        logger.warning(f"Could not determine HA value for {volume_name}. Skipping...")
        return

    # Scale down to HA=1 if needed
    changed_ha = False
    if original_ha_value > 1:
        try:
            reduce_volume_ha_stepwise_excluding_snapshot(
                volume_name,
                original_ha_value,
                1,
                snapshot_id
            )
            changed_ha = True
        except VolumeUpdateError as e:
            logger.error(f"Failed to scale down {volume_name} to HA=1: {str(e)}")
            return
    else:
        logger.debug(f"Volume {volume_name} is already at HA={original_ha_value}, no scale-down needed.")

    # Restore from snapshot
    try:
        restore_volume(volume_name, snapshot_id)
    except VolumeRestoreError as e:
        logger.error(f"Restore failed for {volume_name}: {str(e)}")
        return

    # Scale back up to the original HA if we scaled down
    if changed_ha:
        logger.debug(f"Reverting HA for {volume_name} back to {original_ha_value}")
        current_ha = get_volume_ha(volume_name)
        if current_ha is not None and current_ha != original_ha_value:
            try:
                reduce_volume_ha_stepwise_excluding_snapshot(
                    volume_name,
                    current_ha,
                    original_ha_value,
                    snapshot_id
                )
            except VolumeUpdateError as e:
                logger.error(f"Failed to revert HA for {volume_name} back to {original_ha_value}: {str(e)}")

def main(input_file):
    """
    1) Read volumes from the JSON file.
    2) Dynamically compute widths for 'Index', 'Namespace', 'PVC', 'Name', 'SnapshotID'.
    3) Print a table with a top border, header, data rows, and bottom border.
    4) Ask user which volumes to restore (by index or 'all').
    5) For each selected volume, do the restore logic.
    """
    # ---------------------------------------------------------------------
    # Read JSON
    # ---------------------------------------------------------------------
    try:
        with open(input_file, 'r') as f:
            data = json.load(f)
    except Exception as e:
        logger.error(f"Failed to read or parse {input_file}: {e}")
        return 1  # Return a non-zero code to indicate failure

    if not isinstance(data, dict):
        logger.error("Top-level JSON is not a dictionary.")
        return 1

    backup_info = data.get("backup_info", {})
    if not isinstance(backup_info, dict):
        logger.error("`backup_info` is not a dictionary.")
        return 1

    volumes = backup_info.get("volumes", [])
    if not isinstance(volumes, list):
        logger.error("`volumes` is not a list.")
        return 1

    if not volumes:
        logger.error("No volumes found in the input file.")
        return 1

    # ---------------------------------------------------------------------
    # Build table data
    # ---------------------------------------------------------------------
    table_data = []
    for i, vol in enumerate(volumes):
        if not isinstance(vol, dict):
            logger.warning(f"Volume at index {i} is not a dictionary. Skipping...")
            continue

        vol_namespace = vol.get("namespace", "")
        vol_pvc = vol.get("pvc", "")
        vol_name = vol.get("name", "")
        backup_id = vol.get("backup_id", "")
        snapshot_id = backup_id.split("-")[-1] if backup_id else ""
        table_data.append((str(i), vol_namespace, vol_pvc, vol_name, snapshot_id))

    if not table_data:
        logger.error("All volumes were invalid or missing required fields.")
        return 1

    col_headers = ("Index", "Namespace", "PVC", "Name", "SnapshotID")
    col_widths = [len(h) for h in col_headers]

    # Compute max widths
    for row in table_data:
        for idx, cell_val in enumerate(row):
            col_widths[idx] = max(col_widths[idx], len(cell_val))

    def make_border_line():
        pieces = []
        for w in col_widths:
            pieces.append("+" + "-" * (w + 2))
        pieces.append("+")
        return "".join(pieces)

    # Print the table
    top_border = make_border_line()
    print(top_border)

    header_cells = []
    for idx, header in enumerate(col_headers):
        w = col_widths[idx]
        header_cells.append(f"| {header:<{w}} ")
    header_cells.append("|")
    print("".join(header_cells))

    print(top_border)

    for row in table_data:
        row_str = ""
        for idx, cell_val in enumerate(row):
            w = col_widths[idx]
            row_str += f"| {cell_val:<{w}} "
        row_str += "|"
        print(row_str)

    bottom_border = make_border_line()
    print(bottom_border)

    # ---------------------------------------------------------------------
    # Prompt user
    # ---------------------------------------------------------------------
    print("\nEnter indexes to restore (comma-separated), or type 'all' to restore all volumes:")
    user_input = input("> ").strip().lower()

    if user_input == "all":
        selected_indexes = range(len(table_data))
    else:
        try:
            selected_indexes = [int(x.strip()) for x in user_input.split(",")]
        except ValueError:
            logger.error("Invalid input. Please enter comma-separated numbers or 'all'.")
            return 1

    # ---------------------------------------------------------------------
    # Process selected volumes
    # ---------------------------------------------------------------------
    for idx in selected_indexes:
        if idx < 0 or idx >= len(table_data):
            logger.warning(f"Skipping invalid index: {idx}")
            continue

        process_volume(volumes[idx])  # Process the actual volume dictionary

    return 0  # Indicate success

if __name__ == "__main__":
    """
    Usage:
      python3 final.py <input_json_file>
    Then you'll see a dynamically sized table with columns:
      Index, Namespace, PVC, Name, SnapshotID
    The script prompts for indexes or 'all' to select volumes.
    """
    if len(sys.argv) < 2:
        print(f"Usage: {sys.argv[0]} <input_json_file>")
        sys.exit(1)

    input_file = sys.argv[1]
    exit_code = main(input_file)
    sys.exit(exit_code)

