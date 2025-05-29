from psycopg2 import pool
from sqlalchemy import create_engine
from database_connection.db_config import read_db_config
from src import logger

class DatabaseConnection:
    def __init__(self, db_config: dict):
        self.host = db_config['ods_host']
        self.user = db_config['ods_username']
        self.password = db_config['ods_password']
        self.port = db_config['ods_port']
        self.pool = None
        self.database = None

    def init_pool(self, database: str, minconn: int = 5, maxconn: int = 50):
        self.database = database
        try:
            self.pool = pool.ThreadedConnectionPool(
                minconn,
                maxconn,
                user=self.user,
                password=self.password,
                host=self.host,
                port=self.port,
                database=database
            )
            logger.info(f"Connection pool initialized for {database}")
        except Exception as e:
            logger.exception(f"Failed to initialize connection pool for {database}")
            raise

    def get_conn(self):
        if not self.pool:
            raise Exception("Connection pool not initialized.")
        return self.pool.getconn()

    def put_conn(self, conn):
        if self.pool:
            self.pool.putconn(conn)

    def close_all(self):
        if self.pool:
            self.pool.closeall()

    def get_engine(self):
        return create_engine(f'postgresql://{self.user}:{self.password}@{self.host}:{self.port}/{self.database}')


# Init usage
db_param = read_db_config()
connect_to_db = DatabaseConnection(db_param)
connect_to_db.init_pool('lamisplus_ods_dwh', minconn=10, maxconn=400)
print('successfully connected to database')