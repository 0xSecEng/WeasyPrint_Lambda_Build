## Docker file which builds our Lambda Layer

> test.py file needs to exist
```
FROM lambci/lambda:build-python3.7

# download libraries
RUN yum install -y yum-utils rpmdevtools
WORKDIR /tmp
RUN yumdownloader libffi libffi-devel cairo pango \
    && rpmdev-extract *rpm

# install libraries and set links
RUN mkdir /opt/lib
WORKDIR /opt/lib
RUN cp -P -R /tmp/*/usr/lib64/* /opt/lib
RUN ln libpango-1.0.so.0 pango-1.0
RUN ln libpangocairo-1.0.so.0 pangocairo-1.0

# install weasyprint and dependencies
WORKDIR /opt
RUN pipenv install weasyprint
RUN mkdir -p python/lib/python3.7/site-packages
RUN pipenv lock -r > requirements.txt
RUN pip install -r requirements.txt --no-deps -t python/lib/python3.7/site-packages

# remove warning about cairo < 1.15.4
WORKDIR /opt/python/lib/python3.7/site-packages/weasyprint
RUN sed -i.bak '34,40d' document.py

# run test
WORKDIR /opt
ADD test.py .
RUN pipenv run python test.py

# package lambda layer
WORKDIR /opt
RUN zip -r weasyprint-py37.zip lib python

```

## Our test.py file - exports a dummy pdf to ensure things are working
```py

from weasyprint import HTML
html = HTML(string='<html><body><h1>Hello, world</h1></body></html>')
html.write_pdf('output.pdf')

```

3
```sh

#!/bin/bash

set -e

PYVER=py37

docker image build -f Dockerfile-$PYVER -t weasyprint-$PYVER .
docker create -ti --name dummy-$PYVER weasyprint-$PYVER bash
docker cp dummy-$PYVER:/opt/weasyprint-$PYVER.zip .
docker cp dummy-$PYVER:/opt/output.pdf ./output-$PYVER.pdf
docker rm dummy-$PYVER

aws lambda publish-layer-version --layer-name weasyprint-$PYVER --zip-file fileb://weasyprint-$PYVER.zip

```

## Sample Lambda Function
> Note you need to add the zip file as a lambda layer first
```py

import json
from weasyprint import HTML

data = """
<!DOCTYPE html>
<html>
<body>
<h1>Hello World</h1>
<p>Just Testing.</p>
</body>
</html>
"""

def lambda_handler(event, context):
    HTML(string=data).write_pdf("/tmp/output.pdf")
    return {
        'statusCode': 200,
        'body': json.dumps('Success!')
    }


```


* https://github.com/Kozea/WeasyPrint/issues/1003 -- The one used
* https://github.com/Kozea/WeasyPrint/issues/916 -- other options but did not work for me personally