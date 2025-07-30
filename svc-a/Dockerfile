# Stage 1: Build stage with build dependencies
FROM python:3.10-slim AS builder

WORKDIR /app

# Install dependencies
COPY requirements.txt .
RUN pip install --upgrade pip
RUN pip install --no-cache-dir -r requirements.txt

# Stage 2: Final stage
FROM python:3.10-slim

WORKDIR /app

# Copy installed Python packages and binaries from the builder stage
COPY --from=builder /usr/local/lib/python3.10/site-packages /usr/local/lib/python3.10/site-packages
COPY --from=builder /usr/local/bin /usr/local/bin

# Copy the application code
COPY main.py .

# Expose the port the app runs on
EXPOSE 8000

# Run the application using ddtrace-run
# This command automatically instruments the application.
CMD ["ddtrace-run", "uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]