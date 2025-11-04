FROM python:3.11-slim

WORKDIR /app

# Install Flask
RUN pip install --no-cache-dir flask

# Copy application files
COPY app.py /app/
COPY templates/ /app/templates/

# Create config directory
RUN mkdir -p /config

# Expose port
EXPOSE 5000

# Set environment variables
ENV FLASK_APP=app.py
ENV CONFIG_FILE=/config/piframe-config.json
ENV OVERLAY_FILE=/config/piframe-overlay.json

# Run the application
CMD ["python", "app.py"]
