# Dockerfile for Dia TTS FastAPI App on Cloud Run (GPU)

# Base Image: Use PyTorch with CUDA 12.1 (closer to Cloud Run L4 drivers)
# We will install torch==2.6.0 specifically for CUDA 12.1 later.
# Check PyTorch Docker Hub for the most appropriate recent tag if needed.
FROM pytorch/pytorch:2.1.2-cuda12.1-cudnn8-runtime

# Set non-interactive frontend for apt-get
ENV DEBIAN_FRONTEND=noninteractive

# Install required system dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    libsndfile1 \
    ffmpeg \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Create and switch to a non-root user
RUN useradd --create-home --uid 1001 appuser

USER appuser
WORKDIR /

# --- Dependency Installation ---
# Copy only the requirements file first to leverage Docker cache
COPY --chown=appuser:appuser requirements.txt .

# Upgrade pip
RUN pip install --no-cache-dir --upgrade pip
RUN pip install --no-cache-dir -r requirements.txt
RUN pip install --no-cache-dir torch==2.1.0 torchaudio==2.1.0 -f https://download.pytorch.org/whl/torch_stable.html

# --- End Dependency Installation ---

# Copy the rest of the application code
# (Make sure your FastAPI script is named api.py or change below)
COPY --chown=appuser:appuser . .
# If 'dia' library code is in a subdirectory and needs to be importable:
# COPY --chown=appuser:appuser dia/ ./dia/

# Set environment variables (optional, if your app needs them)
ENV PYTHONUNBUFFERED=1
# ENV USE_GPU=true # Uncomment if api.py checks this variable

# Informational: Expose the default Cloud Run port
# The container needs to listen on the port specified by the $PORT env var.
EXPOSE 8080

# Command to run the application
# Assumes api.py contains the 'app = FastAPI()' object and
# the 'if __name__ == "__main__":' block to run uvicorn, listening on $PORT.
CMD ["python", "api.py"]

# Alternative CMD if api.py only defines the app, without running uvicorn:
# CMD ["uvicorn", "api:app", "--host", "0.0.0.0", "--port", "8080"]