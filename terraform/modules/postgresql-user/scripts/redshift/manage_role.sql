CREATE SCHEMA IF NOT EXISTS ${SCHEMA_NAME};

CREATE OR REPLACE PROCEDURE ${SCHEMA_NAME}.create_user(user_name VARCHAR, user_password VARCHAR, groups VARCHAR) 
AS $$
DECLARE 
  create_sql TEXT;
  alter_sql  TEXT;
  groups_number INT;
  i INT;
  group_name TEXT;
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
  
-- For each group in the groups string, add the user to the group
  
  -- Check if the groups string is not NULL and not empty
  IF groups IS NOT NULL AND groups <> '' THEN
    -- Get the number of groups in the list by counting the occurrences of commas and adding 1
    groups_number := regexp_count(groups, ',') + 1;

    -- Loop through each group in the comma-separated list
    FOR i IN 1..groups_number LOOP
      group_name := trim(split_part(groups, ',', i));
      
      --Check if the group_name string is not empty
      IF group_name <> '' THEN

        -- Check if the group exists
        IF NOT EXISTS (SELECT 1 FROM pg_group WHERE groname = group_name) THEN
          -- If the group doesn't exist, it creates it
          EXECUTE 'CREATE GROUP ' || quote_ident(group_name) || ';';
          RAISE INFO 'Group % created successfully.', group_name;
        END IF;
        
        -- Add user to the group
        EXECUTE 'ALTER GROUP ' || quote_ident(group_name) || ' ADD USER ' || quote_ident(user_name) || ';';
        RAISE INFO 'User % added to group % successfully.', user_name, group_name;

      END IF;
    END LOOP;
  END IF;
EXCEPTION 
  WHEN OTHERS THEN 
    RAISE EXCEPTION 'Error: %', SQLERRM;
END;
$$ LANGUAGE plpgsql;

CALL ${SCHEMA_NAME}.create_user('${USERNAME}', '${PASSWORD}', '${GRANT_GROUPS}');