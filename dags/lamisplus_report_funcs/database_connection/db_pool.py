import os
import sys

from sqlalchemy import create_engine
from sqlalchemy.pool import QueuePool
from database_connection.db_config import read_db_config
from src import logger

db_param = read_db_config()

# Example credentials (replace with actual)
DB_USER = db_param['ods_username']
DB_PASS = db_param['ods_password']
DB_HOST = db_param['ods_host']
DB_PORT = db_param['ods_port']
DB_NAME = db_param['ods_database_name']

engine = create_engine(
    f"postgresql+psycopg2://{DB_USER}:{DB_PASS}@{DB_HOST}:{DB_PORT}/{DB_NAME}",
    poolclass=QueuePool,
    pool_size=900,         # Max persistent connections
    max_overflow=30,      # Temporary burst connections (total max = 30)
    pool_timeout=300,      # Wait max 30s for a free connection
    pool_pre_ping=True,   # Check if connection is alive before use
    echo=False            # Set to True for SQL debug output
)
