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
