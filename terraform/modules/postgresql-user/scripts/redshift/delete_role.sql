CREATE SCHEMA IF NOT EXISTS ${SCHEMA_NAME};

-- Execute external file to create or update a view containing revoke commands for the users
\set schema_name ${SCHEMA_NAME}
\i ./v_generate_user_grant_revoke_ddl.sql

-- Create a procedure to revoke all the privileges of the target_user and, then, to drop it 
CREATE OR REPLACE PROCEDURE ${SCHEMA_NAME}.drop_user_with_revoke(target_user VARCHAR)
LANGUAGE plpgsql
AS $$
DECLARE 
    rec RECORD;
BEGIN
  IF EXISTS (
-- Check if the user exists
    SELECT 1 FROM pg_user WHERE usename = target_user) THEN
      RAISE INFO 'User exists, privileges will be revoked and user will be dropped.';
-- Revokes privileges of the target_user
      FOR rec IN 
          SELECT ddl 
          FROM ${SCHEMA_NAME}.v_generate_user_grant_revoke_ddl
          WHERE grantee = target_user 
          AND ddltype = 'revoke'
          ORDER BY grantseq ASC
      LOOP
          EXECUTE rec.ddl;
      END LOOP;
      RAISE INFO 'Privileges have been revoked correctly.';
-- Drop the target_user
      EXECUTE 'DROP USER "' || target_user || '";';
      RAISE INFO 'User dropped.';
  ELSE
    RAISE INFO 'User does not exist.';
  END IF;
END $$;

-- Execute the procedure
CALL ${SCHEMA_NAME}.drop_user_with_revoke('${USERNAME}');