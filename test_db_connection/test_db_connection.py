import configparser

def read_db_config(filename='config.ini', section='database'):
    # Create a parser
    parser = configparser.ConfigParser()
    # Read the configuration file
    parser.read(filename)
    # Get section, default to database
    db = {}
    if parser.has_section(section):
        params = parser.items(section)
        for param in params:
            db[param[0]] = param[1]
    else:
        raise Exception(f'Section {section} not found in the {filename} file')
    return db

# db_config = read_db_config()
# host = db_config['host']
# port = db_config['port']
# username = db_config['username']
# password = db_config['password']
# database_name = db_config['database_name']

# Example usage
if __name__ == '__main__':
    db_config = read_db_config()
    print(db_config)