CREATE SCHEMA IF NOT EXISTS ${SCHEMA_NAME};

CREATE OR REPLACE PROCEDURE ${SCHEMA_NAME}.create_user(user_name varchar, user_password VARCHAR) 
AS $$
DECLARE 
  create_sql TEXT;
  alter_sql  TEXT;
BEGIN 
-- Check if the user already exists
  IF EXISTS (SELECT 1 FROM pg_user WHERE usename = user_name) THEN
    RAISE INFO 'User already exists, password will be updated.';
-- If it exists, update the password
    alter_sql := 'ALTER USER ' || quote_ident(user_name) || ' WITH PASSWORD ' || quote_literal(user_password) || ';';
    EXECUTE alter_sql;
    
    RAISE INFO 'Password for user % updated successfully.', user_name;
  ELSE
-- If it doesn't exist, create the user
    create_sql := 'CREATE USER ' || quote_ident(user_name) || ' WITH PASSWORD ' || quote_literal(user_password) || ';';
    EXECUTE create_sql;
    
    RAISE INFO 'User % created successfully.', user_name;
  END IF;
EXCEPTION 
  WHEN OTHERS THEN 
    RAISE EXCEPTION 'Error: %', SQLERRM;
END;
$$ LANGUAGE plpgsql;

CALL ${SCHEMA_NAME}.create_user('${USERNAME}', '${PASSWORD}');