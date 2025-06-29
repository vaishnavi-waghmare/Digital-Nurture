-- Exercise 5: Triggers

-- Scenario 1: Automatically update the last modified date when a customer's record is updated
CREATE OR REPLACE TRIGGER UpdateCustomerLastModified
BEFORE UPDATE ON Customers
FOR EACH ROW
BEGIN
    :NEW.LastModified := SYSDATE;
END;
/

-- Test the UpdateCustomerLastModified trigger
SET SERVEROUTPUT ON;
DECLARE
    v_old_date DATE;
    v_new_date DATE;
    v_test_id NUMBER := 1;
BEGIN
    -- Get current LastModified date
    SELECT LastModified INTO v_old_date
    FROM Customers
    WHERE CustomerID = v_test_id;
    
    DBMS_OUTPUT.PUT_LINE('Before update: ' || TO_CHAR(v_old_date, 'DD-MON-YYYY HH24:MI:SS'));
    
    -- Update customer record
    UPDATE Customers
    SET Balance = Balance + 1
    WHERE CustomerID = v_test_id;
    
    -- Get new LastModified date
    SELECT LastModified INTO v_new_date
    FROM Customers
    WHERE CustomerID = v_test_id;
    
    DBMS_OUTPUT.PUT_LINE('After update: ' || TO_CHAR(v_new_date, 'DD-MON-YYYY HH24:MI:SS'));
END;
/

-- Scenario 2: Maintain an audit log for all transactions
CREATE OR REPLACE TRIGGER LogTransaction
AFTER INSERT ON Transactions
FOR EACH ROW
BEGIN
    -- Insert audit log record
    INSERT INTO AuditLog (
        LogID,
        TableName,
        Operation,
        RecordID,
        LogDate,
        UserName,
        Description
    ) VALUES (
        SYS_GUID(),  -- Generate a unique ID
        'Transactions',
        'INSERT',
        :NEW.TransactionID,
        SYSDATE,
        USER,
        'Transaction ' || :NEW.TransactionType || ' of $' || :NEW.Amount || 
        ' on account ' || :NEW.AccountID
    );
END;
/

-- Test the LogTransaction trigger
SET SERVEROUTPUT ON;
DECLARE
    v_transaction_id NUMBER := TransactionID.NEXTVAL;
    v_account_id NUMBER := 1;
    v_amount NUMBER := 100;
    v_audit_count NUMBER;
BEGIN
    -- Insert a new transaction
    INSERT INTO Transactions (
        TransactionID,
        AccountID,
        TransactionDate,
        Amount,
        TransactionType
    ) VALUES (
        v_transaction_id,
        v_account_id,
        SYSDATE,
        v_amount,
        'Deposit'
    );
    
    -- Check audit log
    SELECT COUNT(*) INTO v_audit_count
    FROM AuditLog
    WHERE TableName = 'Transactions' AND RecordID = v_transaction_id;
    
    DBMS_OUTPUT.PUT_LINE('Transaction ' || v_transaction_id || ' inserted.');
    DBMS_OUTPUT.PUT_LINE('Audit records created: ' || v_audit_count);
END;
/

-- Scenario 3: Enforce business rules on deposits and withdrawals
CREATE OR REPLACE TRIGGER CheckTransactionRules
BEFORE INSERT ON Transactions
FOR EACH ROW
DECLARE
    v_account_balance NUMBER;
    e_insufficient_balance EXCEPTION;
    e_invalid_amount EXCEPTION;
BEGIN
    -- Check if amount is positive
    IF :NEW.Amount <= 0 THEN
        RAISE e_invalid_amount;
    END IF;
    
    -- For withdrawals, check if there's sufficient balance
    IF :NEW.TransactionType = 'Withdrawal' THEN
        -- Get current account balance
        SELECT Balance INTO v_account_balance
        FROM Accounts
        WHERE AccountID = :NEW.AccountID;
        
        -- Verify sufficient balance
        IF v_account_balance < :NEW.Amount THEN
            RAISE e_insufficient_balance;
        END IF;
        
        -- Update the account balance
        UPDATE Accounts
        SET Balance = Balance - :NEW.Amount,
            LastModified = SYSDATE
        WHERE AccountID = :NEW.AccountID;
    
    -- For deposits, update the account balance
    ELSIF :NEW.TransactionType = 'Deposit' THEN
        UPDATE Accounts
        SET Balance = Balance + :NEW.Amount,
            LastModified = SYSDATE
        WHERE AccountID = :NEW.AccountID;
    END IF;

EXCEPTION
    WHEN e_invalid_amount THEN
        RAISE_APPLICATION_ERROR(-20001, 'Transaction amount must be greater than zero.');
        
    WHEN e_insufficient_balance THEN
        RAISE_APPLICATION_ERROR(-20002, 'Insufficient funds in account ' || :NEW.AccountID || 
                               '. Required: $' || :NEW.Amount || ', Available: $' || v_account_balance);
        
    WHEN NO_DATA_FOUND THEN
        RAISE_APPLICATION_ERROR(-20003, 'Account not found.');
        
    WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20004, 'Error processing transaction: ' || SQLERRM);
END;
/

-- Test the CheckTransactionRules trigger
SET SERVEROUTPUT ON;
DECLARE
    v_transaction_id NUMBER := TransactionID.NEXTVAL;
    v_account_id NUMBER := 1;
    v_amount NUMBER := 50;  -- Make sure this is less than the account balance for testing
BEGIN
    -- Insert a new withdrawal transaction
    INSERT INTO Transactions (
        TransactionID,
        AccountID,
        TransactionDate,
        Amount,
        TransactionType
    ) VALUES (
        v_transaction_id,
        v_account_id,
        SYSDATE,
        v_amount,
        'Withdrawal'
    );
    
    DBMS_OUTPUT.PUT_LINE('Withdrawal transaction processed successfully.');
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Error: ' || SQLERRM);
END;
/ 