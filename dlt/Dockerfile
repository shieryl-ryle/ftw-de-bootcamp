# syntax=docker/dockerfile:1

FROM python:3.9-slim

# Install system packages
RUN apt-get update \
 && apt-get install -y --no-install-recommends \
      curl \
      unzip \
 && rm -rf /var/lib/apt/lists/*

WORKDIR /var/dlt/pipelines

# Copy & install Python requirements
COPY requirements.txt .
RUN pip install --trusted-host pypi.org --trusted-host pypi.python.org --trusted-host files.pythonhosted.org --no-cache-dir -r requirements.txt

# Copy .dlt secret configuration
COPY .dlt/secrets.toml /var/dlt/.dlt/secrets.toml

# Copy the rest of your pipeline code in
COPY . .