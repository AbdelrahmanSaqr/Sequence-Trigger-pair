DECLARE

--decalre a cursor to containt each tables name and its numeric primary key columns and ignore composite primary keys
    CURSOR PRIMARY_DATA IS
                                        SELECT DT.TABLE_NAME, DT.COLUMN_NAME 
                                        FROM (
                                                SELECT UCC.COLUMN_NAME, UCC.TABLE_NAME, UCC.CONSTRAINT_NAME
                                                FROM
                                                (
                                                    SELECT CONSTRAINT_NAME FROM USER_CONS_COLUMNS GROUP BY  CONSTRAINT_NAME HAVING  COUNT (*) <=1
                                                ) CPK , USER_CONS_COLUMNS UCC
                                                WHERE UCC.CONSTRAINT_NAME = CPK.CONSTRAINT_NAME ) ANO,
                                                USER_CONSTRAINTS PK, USER_TAB_COLUMNS DT
                                        WHERE PK.TABLE_NAME = ANO.TABLE_NAME
                                            AND PK.CONSTRAINT_NAME = ANO.CONSTRAINT_NAME
                                            AND DT.TABLE_NAME = PK.TABLE_NAME
                                            AND DT.COLUMN_NAME = ANO.COLUMN_NAME
                                            AND PK.CONSTRAINT_TYPE='P'          
                                            AND DT.DATA_TYPE = 'NUMBER';
                   
--declare variable to store the start sequence value        
    V_START_SEQ NUMBER(38,0);    
--declare variable to store the sequence name                
    V_SEQ_NAME VARCHAR2(300);     
--declare variable to store the trigger name      
    V_TRIGG_NAME VARCHAR2(300);         

BEGIN

    FOR PRIMARY_REC IN PRIMARY_DATA LOOP

        V_SEQ_NAME := PRIMARY_REC.TABLE_NAME || '_seq';         --sequence name depends on the current table name
        V_TRIGG_NAME := PRIMARY_REC.TABLE_NAME||'_trig';        --trigger name depends on the current table name
        
         --drop existing sequence with the same name 
         BEGIN
            -- Check if the sequence exists before dropping i 
                EXECUTE IMMEDIATE 'DROP SEQUENCE ' || V_SEQ_NAME;
            EXCEPTION
                WHEN OTHERS THEN
                    NULL; -- Ignore if the sequence does not exist
        END;

       
         --find the start sequence value by getting the maximum value in the ID column and increment it by 1 to start after last ID value, if no values in this column start with 0:
        EXECUTE IMMEDIATE 'SELECT NVL(MAX(' || PRIMARY_REC.COLUMN_NAME || '), 0) + 1 FROM ' || PRIMARY_REC.TABLE_NAME
            INTO V_START_SEQ;
       
         
        --create sequence using dynamic SQL:        
         EXECUTE IMMEDIATE          
         'CREATE SEQUENCE ' || V_SEQ_NAME
         ||' START WITH ' || V_START_SEQ
         ||' INCREMENT BY 1';
         
        --create or replace trigger:        
         EXECUTE IMMEDIATE          
         'CREATE OR REPLACE TRIGGER ' || V_TRIGG_NAME 
          || ' BEFORE INSERT ON ' || PRIMARY_REC.TABLE_NAME
          || ' FOR EACH ROW '
          || ' BEGIN '
          || ' :NEW.' || PRIMARY_REC.COLUMN_NAME || ' := ' || V_SEQ_NAME || '.NEXTVAL;'
          || ' END; ';
        

    END LOOP;

END;

insert into Departments (DEPARTMENT_NAME, MANAGER_ID, LOCATION_ID) values ('DM', 200, 1700);