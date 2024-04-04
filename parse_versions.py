import yaml

def parse_docker_images(yaml_data):
    images = []
    for module in yaml_data['modules'].values():
        for image in module.values():
            images.append(image)
    return images

with open('versions.yaml', 'r') as file:
    yaml_data = yaml.safe_load(file)

parsed_yaml = yaml_data
docker_images = parse_docker_images(parsed_yaml)

with open('docker_images.txt', 'w') as f:
    for image in docker_images:
        f.write(image + '\n')
