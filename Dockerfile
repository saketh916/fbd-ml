FROM python:3.10-slim

# Set working directory
WORKDIR /app

# Install Chrome and necessary dependencies (Debian/Ubuntu)
RUN apt-get update && apt-get install -y \
    chromium \
    chromium-driver \
    wget \
    ca-certificates \
    fonts-liberation \
    libnss3 \
    libxss1 \
    libappindicator3-1 \
    libasound2 \
    libatk-bridge2.0-0 \
    libgbm-dev \
    libgtk-3-0 \
    libu2f-udev \
    libvulkan1 \
    --no-install-recommends && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Copy requirements and install Python deps
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Install SpaCy model (will be cached under HF_HOME)
RUN python -m spacy download en_core_web_sm

# Create non-root user and HF cache dir (fix permission issues)
RUN useradd -m -u 1000 user && \
    mkdir -p /app/.cache/huggingface && \
    chown -R user:user /app/.cache

# Set HF cache path so transformers/tokenizers use writable dir
ENV HF_HOME=/app/.cache/huggingface

# Ensure chrome/chromedriver env variables are set (paths from apt packages)
ENV CHROME_PATH=/usr/bin/chromium
ENV CHROMEDRIVER_PATH=/usr/bin/chromedriver

# Copy code (make it belong to user)
COPY --chown=user:user . .

# Switch to non-root
USER user

# Expose port
EXPOSE 7860

# Run the Flask app
CMD ["python", "app.py"]
