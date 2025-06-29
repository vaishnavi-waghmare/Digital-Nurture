-- Exercise 3: Stored Procedures

-- Scenario 1: Process monthly interest for all savings accounts
CREATE OR REPLACE PROCEDURE ProcessMonthlyInterest AS
    v_interest_rate NUMBER := 0.01; -- 1% monthly interest rate
    v_updated_count NUMBER := 0;
    v_interest_amount NUMBER;
    
    CURSOR c_savings_accounts IS
        SELECT AccountID, Balance
        FROM Accounts
        WHERE AccountType = 'Savings';
BEGIN
    -- Set server output on for debugging
    DBMS_OUTPUT.PUT_LINE('Starting monthly interest processing...');
    
    -- Loop through all savings accounts
    FOR acc IN c_savings_accounts LOOP
        -- Calculate interest amount
        v_interest_amount := acc.Balance * v_interest_rate;
        
        -- Update the account balance with interest
        UPDATE Accounts
        SET Balance = Balance + v_interest_amount,
            LastModified = SYSDATE
        WHERE AccountID = acc.AccountID;
        
        v_updated_count := v_updated_count + 1;
        
        -- Log the interest applied
        DBMS_OUTPUT.PUT_LINE('Applied interest of $' || TO_CHAR(v_interest_amount, '999,999.99') ||
                            ' to account ' || acc.AccountID || 
                            '. New balance: $' || TO_CHAR(acc.Balance + v_interest_amount, '999,999.99'));
    END LOOP;
    
    -- Commit the changes
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('Monthly interest processing completed. Updated ' || v_updated_count || ' account(s).');
    
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('Error occurred: ' || SQLERRM);
END ProcessMonthlyInterest;
/

-- Scenario 2: Update employee bonuses based on department
CREATE OR REPLACE PROCEDURE UpdateEmployeeBonus(
    p_department IN VARCHAR2,
    p_bonus_percentage IN NUMBER
) AS
    v_updated_count NUMBER := 0;
    
    CURSOR c_employees IS
        SELECT EmployeeID, Name, Salary
        FROM Employees
        WHERE Department = p_department;
BEGIN
    -- Validate input parameters
    IF p_bonus_percentage < 0 THEN
        DBMS_OUTPUT.PUT_LINE('ERROR: Bonus percentage cannot be negative.');
        RETURN;
    END IF;
    
    -- Loop through all employees in the specified department
    FOR emp IN c_employees LOOP
        -- Calculate bonus amount
        UPDATE Employees
        SET Salary = Salary * (1 + p_bonus_percentage/100)
        WHERE EmployeeID = emp.EmployeeID;
        
        v_updated_count := v_updated_count + 1;
        
        -- Log the bonus applied
        DBMS_OUTPUT.PUT_LINE('Applied ' || p_bonus_percentage || '% bonus to ' || emp.Name || 
                            '. New salary: $' || TO_CHAR(emp.Salary * (1 + p_bonus_percentage/100), '999,999.99'));
    END LOOP;
    
    -- Commit the changes
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('Employee bonus update completed. Updated ' || v_updated_count || ' employee(s) in ' || p_department || ' department.');
    
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('Error occurred: ' || SQLERRM);
END UpdateEmployeeBonus;
/

-- Scenario 3: Transfer funds between accounts
CREATE OR REPLACE PROCEDURE TransferFunds(
    p_source_account IN NUMBER,
    p_dest_account IN NUMBER,
    p_amount IN NUMBER
) AS
    v_source_balance NUMBER;
    e_insufficient_funds EXCEPTION;
BEGIN
    -- Validate input parameters
    IF p_amount <= 0 THEN
        DBMS_OUTPUT.PUT_LINE('ERROR: Transfer amount must be positive.');
        RETURN;
    END IF;
    
    -- Get source account balance
    SELECT Balance INTO v_source_balance
    FROM Accounts
    WHERE AccountID = p_source_account;
    
    -- Check if source account has sufficient balance
    IF v_source_balance < p_amount THEN
        RAISE e_insufficient_funds;
    END IF;
    
    -- Start a transaction
    SAVEPOINT start_transfer;
    
    -- Deduct from source account
    UPDATE Accounts
    SET Balance = Balance - p_amount,
        LastModified = SYSDATE
    WHERE AccountID = p_source_account;
    
    -- Add to destination account
    UPDATE Accounts
    SET Balance = Balance + p_amount,
        LastModified = SYSDATE
    WHERE AccountID = p_dest_account;
    
    -- Insert transaction records
    INSERT INTO Transactions (TransactionID, AccountID, TransactionDate, Amount, TransactionType)
    VALUES (TransactionID.NEXTVAL, p_source_account, SYSDATE, p_amount, 'Withdrawal');
    
    INSERT INTO Transactions (TransactionID, AccountID, TransactionDate, Amount, TransactionType)
    VALUES (TransactionID.NEXTVAL, p_dest_account, SYSDATE, p_amount, 'Deposit');
    
    -- Commit the transaction
    COMMIT;
    
    DBMS_OUTPUT.PUT_LINE('Successfully transferred $' || p_amount || 
                         ' from account ' || p_source_account || 
                         ' to account ' || p_dest_account);
    
EXCEPTION
    WHEN e_insufficient_funds THEN
        ROLLBACK TO start_transfer;
        DBMS_OUTPUT.PUT_LINE('ERROR: Insufficient funds in account ' || p_source_account || 
                             '. Required: $' || p_amount || ', Available: $' || v_source_balance);
        
    WHEN NO_DATA_FOUND THEN
        ROLLBACK TO start_transfer;
        DBMS_OUTPUT.PUT_LINE('ERROR: Account not found. Please verify account numbers.');
        
    WHEN OTHERS THEN
        ROLLBACK TO start_transfer;
        DBMS_OUTPUT.PUT_LINE('ERROR: An unexpected error occurred: ' || SQLERRM);
END TransferFunds;
/ 