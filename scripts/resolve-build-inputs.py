"""Keep registry image names independent of the checked-out eCash source."""
import os
import re

DEFAULT_SOURCE_REF = '18b38ad'


def resolve(event, image_tag, source_ref=''):
    if not re.fullmatch(r'[A-Za-z0-9_][A-Za-z0-9_.-]{0,127}', image_tag or ''):
        raise ValueError('Choose a valid, nonempty Docker image tag')
    if event == 'push':
        # Preserve the existing historical short-SHA tag/source binding.
        source = image_tag if re.fullmatch(r'[0-9a-fA-F]{7,40}', image_tag) else DEFAULT_SOURCE_REF
    elif event == 'workflow_dispatch':
        source = source_ref or DEFAULT_SOURCE_REF
    else:
        raise ValueError('Publishing supports tag pushes or manual dispatch only')
    if not re.fullmatch(r'[A-Za-z0-9][A-Za-z0-9_./-]*', source):
        raise ValueError('Choose a source commit or ordinary upstream branch/tag ref')
    return image_tag, source


if __name__ == '__main__':
    try:
        tag, source = resolve(os.environ.get('BUILD_EVENT', ''),
                              os.environ.get('IMAGE_TAG_INPUT', ''),
                              os.environ.get('SOURCE_REF_INPUT', ''))
    except ValueError as error:
        raise SystemExit(str(error)) from None
    print('TAG=' + tag)
    print('SOURCE_REF=' + source)
