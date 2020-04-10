import subprocess
import argparse
import datetime

VERSION = "3.12.1"

def log(message: str):
    print(message)


def build_docker(image_name: str, date_string: str, with_latest_tag: bool, dockerfile: str) -> None:
    cmd = [
        'docker',
        'build',
        '-f',
        dockerfile
    ]

    cmd.extend([
        '-t',
        f'{image_name}:{VERSION}'
    ])

    cmd.extend([
        '-t',
        f'{image_name}:{VERSION}-{date_string}'
    ])

    if with_latest_tag:
        cmd.extend([
            '-t',
            f'{image_name}:latest'
        ])

    cmd.extend([
        '.'
    ])

    log('running: ' + ' '.join(cmd))

    subprocess.check_call(cmd)


def push_docker(image_name: str, date_string: str, with_latest_tag: bool) -> None:
    to_push = [
        f'{image_name}:{VERSION}',
        f'{image_name}:{VERSION}-{date_string}'
    ]

    if with_latest_tag:
        to_push.extend([
            f'{image_name}:latest'
        ])

    for image in to_push:
        log('pushing ' + image)

        cmd = [
            'docker',
            'push',
            image
        ]

        log('running: ' + ' '.join(cmd))

        subprocess.check_call(cmd)


def str2bool(v):
    if isinstance(v, bool):
       return v
    if v.lower() in ('yes', 'true', 't', 'y', '1'):
        return True
    elif v.lower() in ('no', 'false', 'f', 'n', '0'):
        return False
    else:
        raise argparse.ArgumentTypeError('Boolean value expected.')


parser = argparse.ArgumentParser(description='Builds docker-ts3server')
parser.add_argument('--withLatestTag', type=str2bool, help='whether to use the latest tag or not', required=False, nargs='?', const=True, default=False)
parser.add_argument('--imageName', type=str, help='image name (with registry url) to tag the resulting docker image with', required=True)
parser.add_argument('--alpine', type=str2bool, help='whether to use alpine instead of debian or not', required=False, nargs='?', const=True, default=False)

args = vars(parser.parse_args())

with_latest_tag: bool = False
if 'withLatestTag' in args:
    with_latest_tag = args['withLatestTag']

image_name: str = args['imageName']

dockerfile = "Dockerfile"

if 'alpine' in args and args['alpine']:
    dockerfile = "alpine.Dockerfile"


today = datetime.datetime.now()
date_string = today.strftime("%Y-%m-%d-%H-%M-%S")

# MAIN BEGINS HERE:
build_docker(image_name=image_name, date_string=date_string, with_latest_tag=with_latest_tag, dockerfile=dockerfile)
push_docker(image_name=image_name, date_string=date_string, with_latest_tag=with_latest_tag)

