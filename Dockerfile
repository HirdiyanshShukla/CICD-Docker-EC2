FROM python:3.12-slim

WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

# 🔒 Checkov standard: Never run as root!
RUN useradd -m appuser && chown -R appuser /app
USER appuser

# 🩺 Healthcheck for Docker Checkov compliance
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
  CMD curl --fail http://localhost:8000/ || exit 1

EXPOSE 8000

# 🚀 Dynamic execution based on environment
CMD ["python", "main/manage.py", "runserver", "0.0.0.0:8000"]
