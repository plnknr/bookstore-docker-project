# Use a lightweight version of Python as the base image
FROM python:alpine

# Copy the requirements.txt file to the root directory of the container
COPY requirements.txt requirements.txt

# Install Python dependencies from the requirements.txt file
RUN pip install -r requirements.txt

# Set the working directory to /app
WORKDIR /app

# Copy all application files from the local directory to the /app directory in the container
COPY . /app

# Expose port 80 on the container but it is just given information we can not change port number
EXPOSE 80

# Command to run the application when the container starts
CMD python ./bookstore-api.py