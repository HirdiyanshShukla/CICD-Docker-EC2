FROM python:3.12-slim

WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy your code into the container
COPY . .

# Create a non-root user
RUN useradd -m appuser

# Give the non-root user explicit ownership of the working directory so it can create/modify the sqlite3 database
RUN chown -R appuser:appuser /app

# Switch to the non-root user
USER appuser

# 🩺 Healthcheck for Docker Checkov compliance
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
  CMD curl --fail http://localhost:8000/ || exit 1

EXPOSE 8000

# Run Django, forcing it to listen on all interfaces
CMD ["python", "main/manage.py", "runserver", "0.0.0.0:8000"]
