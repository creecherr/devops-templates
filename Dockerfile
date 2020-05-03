# this is an official Python runtime, used as the parent image
FROM insert-registry-here/python36

LABEL maintainer="Haley Creech <haley.creech@gmail.com>"

# We need a non-root user
RUN useradd -d /devops-demo pyrunner

# Become the 'pyrunner' user.
USER pyrunner

# set the working directory in the container to /app
WORKDIR /devops-demo

# add the current directory to the container as /app
ADD . /devops-demo

RUN pip3 install --user -r requirements.txt

# unblock port 80 for the Flask app to run on
EXPOSE 5001

# execute the Flask app
CMD ["python3", "app.py"]
