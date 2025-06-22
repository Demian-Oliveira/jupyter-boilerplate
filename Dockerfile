FROM jupyter/pyspark-notebook

WORKDIR /home/src
ADD requirements.txt .

# --- Custom section added by Demian Oliveira ----------------------------
# Temporarily switch to root to install system-level dependencies required
# for building Python packages like psycopg2-binary (PostgreSQL client).
USER root

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        build-essential \
        python3-dev \
        libpq-dev \
        gcc && \
    rm -rf /var/lib/apt/lists/*

# Revert to the default non-root notebook user for security and compatibility
# with the Jupyter environment.
USER ${NB_UID}

# Using binary wheels (recommended for Docker) to speed up install and avoid build issues
RUN pip install --upgrade pip wheel && \
    pip install --prefer-binary -r requirements.txt
# -----------------------------------------------------------------------
