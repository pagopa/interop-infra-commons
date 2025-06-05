-- Reference: https://github.com/awslabs/amazon-redshift-utils/blob/master/src/AdminViews/v_generate_user_grant_revoke_ddl.sql
-- A fix has been applied to row 184: function replace() helps in removing double quotes from the object name, otherwise there will be a syntax error.

CREATE OR REPLACE VIEW :schema_name.v_generate_user_grant_revoke_ddl AS
WITH objprivs AS ( 
SELECT objowner, 
      schemaname, 
      objname, 
      objtype,
      CASE WHEN split_part(aclstring,'=',1)='' THEN 'PUBLIC'::text ELSE translate(trim(split_part(aclstring,'=',1)::text),'"','')::text END::text AS grantee,
      translate(trim(split_part(aclstring,'/',2)::text),'"','')::text AS grantor, 
      trim(split_part(split_part(aclstring,'=',2),'/',1))::text AS privilege, 
      CASE WHEN objtype = 'default acl' THEN QUOTE_IDENT(objname) 
            WHEN objtype in ('procedure','function') AND regexp_instr(objname, schemaname) > 0 THEN QUOTE_IDENT(objname)
            WHEN objtype in ('procedure','function','column') THEN QUOTE_IDENT(schemaname)||'.'||QUOTE_IDENT(objname) 
            ELSE nvl(QUOTE_IDENT(schemaname)||'.'||QUOTE_IDENT(objname),QUOTE_IDENT(objname)) END::varchar(5000) as fullobjname,
      CASE WHEN split_part(aclstring,'=',1)='' THEN 'PUBLIC' 
      ELSE trim(split_part(aclstring,'=',1)) 
      END::text as splitgrantee,
      grantseq,
      colname 
      FROM (
            -- TABLE AND VIEW privileges
            SELECT pg_get_userbyid(b.relowner)::text AS objowner, 
            trim(c.nspname)::text AS schemaname,  
            b.relname::varchar(5000) AS objname,
            CASE WHEN relkind='r' THEN 'table' ELSE 'view' END::text AS objtype, 
            TRIM(SPLIT_PART(array_to_string(b.relacl,','), ',', NS.n))::varchar(500) AS aclstring, 
            NS.n as grantseq,
            null::text as colname
            FROM 
            (SELECT oid,generate_series(1,array_upper(relacl,1))  AS n FROM pg_catalog.pg_class) NS
            INNER JOIN pg_catalog.pg_class B ON b.oid = ns.oid AND  NS.n <= array_upper(b.relacl,1)
            INNER JOIN pg_catalog.pg_namespace c on b.relnamespace = c.oid
            where relkind in ('r','v')
            UNION ALL
            -- TABLE AND VIEW column privileges
            SELECT pg_get_userbyid(c.relowner)::text AS objowner, 
            trim(d.nspname)::text AS schemaname,  
            c.relname::varchar(5000) AS objname,
            'column'::text AS objtype, 
            TRIM(SPLIT_PART(array_to_string(b.attacl,','), ',', NS.n))::varchar(500) AS aclstring, 
            NS.n as grantseq,
            b.attname::text as colname
            FROM 
            (SELECT attrelid,generate_series(1,array_upper(attacl,1))  AS n FROM pg_catalog.pg_attribute_info) NS
            INNER JOIN pg_catalog.pg_attribute_info B ON b.attrelid = ns.attrelid AND  NS.n <= array_upper(b.attacl,1)
            INNER JOIN pg_catalog.pg_class c on b.attrelid = c.oid
            INNER JOIN pg_catalog.pg_namespace d on c.relnamespace = d.oid
            where relkind in ('r','v')
            UNION ALL
            -- SCHEMA privileges
            SELECT pg_get_userbyid(b.nspowner)::text AS objowner,
            null::text AS schemaname,
            b.nspname::varchar(5000) AS objname,
            'schema'::text AS objtype,
            TRIM(SPLIT_PART(array_to_string(b.nspacl,','), ',', NS.n))::varchar(500) AS aclstring,
            NS.n as grantseq,
            null::text as colname
            FROM 
            (SELECT oid,generate_series(1,array_upper(nspacl,1)) AS n FROM pg_catalog.pg_namespace) NS
            INNER JOIN pg_catalog.pg_namespace B ON b.oid = ns.oid AND NS.n <= array_upper(b.nspacl,1)
            UNION ALL
            -- DATABASE privileges
            SELECT pg_get_userbyid(b.datdba)::text AS objowner,
            null::text AS schemaname,
            b.datname::varchar(5000) AS objname,
            'database'::text AS objtype,
            TRIM(SPLIT_PART(array_to_string(b.datacl,','), ',', NS.n))::varchar(500) AS aclstring,
            NS.n as grantseq,
            null::text as colname
            FROM 
            (SELECT oid,generate_series(1,array_upper(datacl,1)) AS n FROM pg_catalog.pg_database) NS
            INNER JOIN pg_catalog.pg_database B ON b.oid = ns.oid AND NS.n <= array_upper(b.datacl,1) 
            UNION ALL
            -- FUNCTION privileges 
            SELECT pg_get_userbyid(b.proowner)::text AS objowner,
            trim(c.nspname)::text AS schemaname, 
            textin(regprocedureout(b.oid::regprocedure))::varchar(5000) AS objname,
            decode(prorettype,0,'procedure','function')::text AS objtype,
            TRIM(SPLIT_PART(array_to_string(b.proacl,','), ',', NS.n))::varchar(500) AS aclstring,
            NS.n as grantseq,
            null::text as colname  
            FROM 
            (SELECT oid,generate_series(1,array_upper(proacl,1)) AS n FROM pg_catalog.pg_proc) NS
            INNER JOIN pg_catalog.pg_proc B ON b.oid = ns.oid and NS.n <= array_upper(b.proacl,1)
            INNER JOIN pg_catalog.pg_namespace c on b.pronamespace=c.oid 
            UNION ALL
            -- LANGUAGE privileges
            SELECT null::text AS objowner,
            null::text AS schemaname,
            lanname::varchar(5000) AS objname,
            'language'::text AS objtype,
            TRIM(SPLIT_PART(array_to_string(b.lanacl,','), ',', NS.n))::varchar(500) AS aclstring,
            NS.n as grantseq, 
            null::text as colname
            FROM 
            (SELECT oid,generate_series(1,array_upper(lanacl,1)) AS n FROM pg_catalog.pg_language) NS
            INNER JOIN pg_catalog.pg_language B ON b.oid = ns.oid and NS.n <= array_upper(b.lanacl,1)
            UNION ALL
            -- DEFAULT ACL privileges
            SELECT pg_get_userbyid(b.defacluser)::text AS objowner,
            trim(c.nspname)::text AS schemaname,
            decode(b.defaclobjtype,'r','tables','f','functions','p','procedures')::varchar(5000) AS objname,
            'default acl'::text AS objtype,
            TRIM(SPLIT_PART(array_to_string(b.defaclacl,','), ',', NS.n))::varchar(500) AS aclstring,
            NS.n as grantseq, 
            null::text as colname
            FROM 
            (SELECT oid,generate_series(1,array_upper(defaclacl,1)) AS n FROM pg_catalog.pg_default_acl) NS
            INNER JOIN pg_catalog.pg_default_acl b ON b.oid = ns.oid and NS.n <= array_upper(b.defaclacl,1) 
            LEFT JOIN  pg_catalog.pg_namespace c on b.defaclnamespace=c.oid
      ) 
      where  ( ((split_part(aclstring,'=',1) = split_part(aclstring,'/',2) AND privilege in ('arwdRxtD','a*r*w*d*R*x*t*D*')) OR split_part(aclstring,'=',1) <> split_part(aclstring,'/',2))
      -- split_part(aclstring,'=',1) <> split_part(aclstring,'/',2)
      AND split_part(aclstring,'=',1) <> 'rdsdb'
      AND NOT (split_part(aclstring,'=',1)='' AND split_part(aclstring,'/',2) = 'rdsdb')) 
)
-- Extract object GRANTS
SELECT objowner::text, schemaname::text, objname::varchar(5000), objtype::text, grantor::text, grantee::text, 'grant'::text AS ddltype, grantseq,
decode(objtype,'database',0,'schema',1,'language',1,'table',2,'view',2,'column',2,'function',2,'procedure',2,'default acl',3) AS objseq,
CASE WHEN (grantor <> current_user AND grantor <> 'rdsdb' AND objtype <> 'default acl') 
THEN 'SET SESSION AUTHORIZATION '||QUOTE_IDENT(grantor)||';' ELSE '' END::varchar(5000)||
(CASE WHEN privilege = 'arwdRxtD' OR privilege = 'a*r*w*d*R*x*t*D*' THEN (CASE WHEN objtype = 'default acl' THEN 'ALTER DEFAULT PRIVILEGES for user '||QUOTE_IDENT(grantor)||nvl(' in schema '||QUOTE_IDENT(schemaname)||' ',' ')
ELSE '' END::varchar(5000))||'GRANT ALL on '||fullobjname||' to '||splitgrantee||
(CASE WHEN privilege = 'a*r*w*d*R*x*t*D*' THEN ' WITH GRANT OPTION;' ELSE ';' END::varchar(5000)) 
when privilege = 'UC' OR privilege = 'U*C*' THEN (CASE WHEN objtype = 'default acl' THEN 'ALTER DEFAULT PRIVILEGES for user '||QUOTE_IDENT(grantor)||nvl(' in schema '||QUOTE_IDENT(schemaname)||' ',' ')
ELSE '' END::varchar(5000))||'GRANT ALL on '||objtype||' '||fullobjname||' to '||splitgrantee||
(CASE WHEN privilege = 'U*C*' THEN ' WITH GRANT OPTION;' ELSE ';' END::varchar(5000)) 
when privilege = 'CT' OR privilege = 'U*C*' THEN (CASE WHEN objtype = 'default acl' THEN 'ALTER DEFAULT PRIVILEGES for user '||QUOTE_IDENT(grantor)||nvl(' in schema '||QUOTE_IDENT(schemaname)||' ',' ')
ELSE '' END::varchar(5000))||'GRANT ALL on '||objtype||' '||fullobjname||' to '||splitgrantee||
(CASE WHEN privilege = 'C*T*' THEN ' WITH GRANT OPTION;' ELSE ';' END::varchar(5000))
ELSE  
(
CASE WHEN charindex('a',privilege) > 0 THEN (CASE WHEN objtype = 'default acl' THEN 'ALTER DEFAULT PRIVILEGES for user '||QUOTE_IDENT(grantor)||nvl(' in schema '||QUOTE_IDENT(schemaname)||' ',' ')
ELSE '' END::varchar(5000))||'GRANT INSERT on '||fullobjname||' to '||splitgrantee|| 
(CASE WHEN charindex('a*',privilege) > 0 THEN ' WITH GRANT OPTION;' ELSE ';' END::varchar(5000)) ELSE '' END::varchar(5000)||
CASE WHEN charindex('r',privilege) > 0 THEN (CASE WHEN objtype = 'default acl' THEN 'ALTER DEFAULT PRIVILEGES for user '||QUOTE_IDENT(grantor)||nvl(' in schema '||QUOTE_IDENT(schemaname)||' ',' ')
ELSE '' END::varchar(5000))||'GRANT SELECT '||CASE WHEN objtype='column' then '('||colname||')' else '' END::text||' on '||fullobjname||' to '||splitgrantee||
(CASE WHEN charindex('r*',privilege) > 0 THEN ' WITH GRANT OPTION;' ELSE ';' END::varchar(5000)) ELSE '' END::varchar(5000)||
CASE WHEN charindex('w',privilege) > 0 THEN (CASE WHEN objtype = 'default acl' THEN 'ALTER DEFAULT PRIVILEGES for user '||QUOTE_IDENT(grantor)||nvl(' in schema '||QUOTE_IDENT(schemaname)||' ',' ')
ELSE '' END::varchar(5000))||'GRANT UPDATE '||CASE WHEN objtype='column' then '('||colname||')' else '' END::text||' on '||fullobjname||' to '||splitgrantee||
(CASE WHEN charindex('w*',privilege) > 0 THEN ' WITH GRANT OPTION;' ELSE ';' END::varchar(5000)) ELSE '' END::varchar(5000)||
CASE WHEN charindex('d',privilege) > 0 THEN (CASE WHEN objtype = 'default acl' THEN 'ALTER DEFAULT PRIVILEGES for user '||QUOTE_IDENT(grantor)||nvl(' in schema '||QUOTE_IDENT(schemaname)||' ',' ')
ELSE '' END::varchar(5000))||'GRANT DELETE on '||fullobjname||' to '||splitgrantee||
(CASE WHEN charindex('d*',privilege) > 0 THEN ' WITH GRANT OPTION;' ELSE ';' END::varchar(5000)) ELSE '' END::varchar(5000)||

CASE WHEN charindex('D',privilege) > 0 THEN (CASE WHEN objtype = 'default acl' THEN '-- ALTER DEFAULT PRIVILEGES for user '||QUOTE_IDENT(grantor)||nvl(' in schema '||QUOTE_IDENT(schemaname)||' ',' ')
ELSE '' END::varchar(5000))||'GRANT DROP on '||fullobjname||' to '||splitgrantee||
(CASE WHEN charindex('d*',privilege) > 0 THEN ' WITH GRANT OPTION;' ELSE ';' END::varchar(5000)) ELSE '' END::varchar(5000)||


CASE WHEN charindex('R',privilege) > 0 THEN (CASE WHEN objtype = 'default acl' THEN 'ALTER DEFAULT PRIVILEGES for user '||QUOTE_IDENT(grantor)||nvl(' in schema '||QUOTE_IDENT(schemaname)||' ',' ')
ELSE '' END::varchar(5000))||'GRANT RULE on '||fullobjname||' to '||splitgrantee||
(CASE WHEN charindex('R*',privilege) > 0 THEN ' WITH GRANT OPTION;' ELSE ';' END::varchar(5000)) ELSE '' END::varchar(5000)||
CASE WHEN charindex('x',privilege) > 0 THEN (CASE WHEN objtype = 'default acl' THEN 'ALTER DEFAULT PRIVILEGES for user '||QUOTE_IDENT(grantor)||nvl(' in schema '||QUOTE_IDENT(schemaname)||' ',' ')
ELSE '' END::varchar(5000))||'GRANT REFERENCES on '||fullobjname||' to '||splitgrantee||
(CASE WHEN charindex('x*',privilege) > 0 THEN ' WITH GRANT OPTION;' ELSE ';' END::varchar(5000)) ELSE '' END::varchar(5000)||
CASE WHEN charindex('t',privilege) > 0 THEN (CASE WHEN objtype = 'default acl' THEN 'ALTER DEFAULT PRIVILEGES for user '||QUOTE_IDENT(grantor)||nvl(' in schema '||QUOTE_IDENT(schemaname)||' ',' ')
ELSE '' END::varchar(5000))||'GRANT TRIGGER on '||fullobjname||' to '||splitgrantee||
(CASE WHEN charindex('t*',privilege) > 0 THEN ' WITH GRANT OPTION;' ELSE ';' END::varchar(5000)) ELSE '' END::varchar(5000)||
CASE WHEN charindex('U',privilege) > 0 THEN (CASE WHEN objtype = 'default acl' THEN 'ALTER DEFAULT PRIVILEGES for user '||QUOTE_IDENT(grantor)||nvl(' in schema '||QUOTE_IDENT(schemaname)||' ',' ')
ELSE '' END::varchar(5000))||'GRANT USAGE on '||objtype||' '||fullobjname||' to '||splitgrantee||
(CASE WHEN charindex('U*',privilege) > 0 THEN ' WITH GRANT OPTION;' ELSE ';' END::varchar(5000)) ELSE '' END::varchar(5000)||
CASE WHEN charindex('C',privilege) > 0 THEN (CASE WHEN objtype = 'default acl' THEN 'ALTER DEFAULT PRIVILEGES for user '||QUOTE_IDENT(grantor)||nvl(' in schema '||QUOTE_IDENT(schemaname)||' ',' ')
ELSE '' END::varchar(5000))||'GRANT CREATE on '||objtype||' '||fullobjname||' to '||splitgrantee||
(CASE WHEN charindex('C*',privilege) > 0 THEN ' WITH GRANT OPTION;' ELSE ';' END::varchar(5000)) ELSE '' END::varchar(5000)||
CASE WHEN charindex('T',privilege) > 0 THEN (CASE WHEN objtype = 'default acl' THEN 'ALTER DEFAULT PRIVILEGES for user '||QUOTE_IDENT(grantor)||nvl(' in schema '||QUOTE_IDENT(schemaname)||' ',' ')
ELSE '' END::varchar(5000))||'GRANT TEMP on '||objtype||' '||fullobjname||' to '||splitgrantee||
(CASE WHEN charindex('T*',privilege) > 0 THEN ' WITH GRANT OPTION;' ELSE ';' END::varchar(5000)) ELSE '' END::varchar(5000)||
CASE WHEN charindex('X',privilege) > 0 THEN (CASE WHEN objtype = 'default acl' THEN 'ALTER DEFAULT PRIVILEGES for user '||QUOTE_IDENT(grantor)||nvl(' in schema '||QUOTE_IDENT(schemaname)||' ',' ')
ELSE '' END::varchar(5000))||'GRANT EXECUTE on '||
(CASE WHEN objtype = 'default acl' THEN '' ELSE objtype||' ' END::varchar(5000))||fullobjname||' to '||splitgrantee||
(CASE WHEN charindex('X*',privilege) > 0 THEN ' WITH GRANT OPTION;' ELSE ';' END::varchar(5000)) ELSE '' END::varchar(5000)
) END::varchar(5000))|| 
CASE WHEN (grantor <> current_user AND grantor <> 'rdsdb' AND objtype <> 'default acl') THEN 'RESET SESSION AUTHORIZATION;' ELSE '' END::varchar(5000) AS ddl, colname
FROM objprivs
UNION ALL
-- Extract object REVOKES
SELECT objowner::text, schemaname::text, objname::varchar(5000), objtype::text, grantor::text, grantee::text, 'revoke'::text AS ddltype, grantseq,
decode(objtype,'default acl',0,'function',0,'procedure',1,'table',1,'view',1,'column',1,'schema',2,'language',2,'database',3) AS objseq,
CASE WHEN (grantor <> current_user AND grantor <> 'rdsdb' AND objtype <> 'default acl' AND grantor <> objowner) THEN 'SET SESSION AUTHORIZATION '||QUOTE_IDENT(grantor)||';' ELSE '' END::varchar(5000)||
(CASE WHEN objtype = 'default acl' THEN 'ALTER DEFAULT PRIVILEGES for user '||QUOTE_IDENT(grantor)||nvl(' in schema '||QUOTE_IDENT(schemaname)||' ',' ')
||'REVOKE ALL on '||replace(fullobjname, '"', '')||' FROM '||splitgrantee||';'
ELSE 'REVOKE ALL on '||(CASE WHEN objtype in ('table', 'view', 'column') THEN '' ELSE objtype||' ' END::varchar(5000))||fullobjname||' FROM '||splitgrantee||';' END::varchar(5000))||
CASE WHEN (grantor <> current_user AND grantor <> 'rdsdb' AND objtype <> 'default acl' AND grantor <> objowner) THEN 'RESET SESSION AUTHORIZATION;' ELSE '' END::varchar(5000) AS ddl, colname
FROM objprivs
WHERE NOT (objtype = 'default acl' AND grantee = 'PUBLIC' and objname in ('functions'))
UNION ALL
-- Eliminate empty default ACLs
SELECT null::text AS objowner, null::text AS schemaname, decode(b.defaclobjtype,'r','tables','f','functions','p','procedures')::varchar(5000) AS objname,
            'default acl'::text AS objtype,  pg_get_userbyid(b.defacluser)::text AS grantor, null::text AS grantee, 'revoke'::text AS ddltype, 5 as grantseq, 5 AS objseq,
  'ALTER DEFAULT PRIVILEGES for user '||QUOTE_IDENT(pg_get_userbyid(b.defacluser))||' GRANT ALL on '||decode(b.defaclobjtype,'r','tables','f','functions','p','procedures')||' TO '||QUOTE_IDENT(pg_get_userbyid(b.defacluser))||
CASE WHEN b.defaclobjtype = 'f' THEN ', PUBLIC;' ELSE ';' END::varchar(5000) AS ddl, null::text as colname FROM pg_catalog.pg_default_acl b where b.defaclacl = '{}'::aclitem[] or (defaclnamespace=0 and defaclobjtype='f');