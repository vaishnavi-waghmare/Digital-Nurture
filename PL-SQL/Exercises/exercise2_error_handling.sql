-- Exercise 2: Error Handling

-- Scenario 1: Handle exceptions during fund transfers between accounts
CREATE OR REPLACE PROCEDURE SafeTransferFunds(
    p_source_account IN NUMBER,
    p_dest_account IN NUMBER,
    p_amount IN NUMBER
) AS
    v_source_balance NUMBER;
    e_insufficient_funds EXCEPTION;
    v_log_message VARCHAR2(200);
BEGIN
    -- Start a transaction
    SAVEPOINT start_transfer;
    
    -- Check if source account has sufficient balance
    SELECT Balance INTO v_source_balance
    FROM Accounts
    WHERE AccountID = p_source_account;
    
    IF v_source_balance < p_amount THEN
        RAISE e_insufficient_funds;
    END IF;
    
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
    
    -- Commit the transaction
    COMMIT;
    
    -- Log successful transaction
    v_log_message := 'Successfully transferred $' || p_amount || 
                     ' from account ' || p_source_account || 
                     ' to account ' || p_dest_account;
    DBMS_OUTPUT.PUT_LINE(v_log_message);
    
EXCEPTION
    WHEN e_insufficient_funds THEN
        ROLLBACK TO start_transfer;
        v_log_message := 'ERROR: Insufficient funds in account ' || p_source_account || 
                         '. Required: $' || p_amount || ', Available: $' || v_source_balance;
        DBMS_OUTPUT.PUT_LINE(v_log_message);
        
    WHEN NO_DATA_FOUND THEN
        ROLLBACK TO start_transfer;
        v_log_message := 'ERROR: Account not found. Please verify account numbers.';
        DBMS_OUTPUT.PUT_LINE(v_log_message);
        
    WHEN OTHERS THEN
        ROLLBACK TO start_transfer;
        v_log_message := 'ERROR: An unexpected error occurred during transfer: ' || SQLERRM;
        DBMS_OUTPUT.PUT_LINE(v_log_message);
END SafeTransferFunds;
/

-- Scenario 2: Manage errors when updating employee salaries
CREATE OR REPLACE PROCEDURE UpdateSalary(
    p_emp_id IN NUMBER,
    p_percentage IN NUMBER
) AS
    v_log_message VARCHAR2(200);
    v_salary Employees.Salary%TYPE;
BEGIN
    -- Validate input parameters
    IF p_percentage < 0 THEN
        v_log_message := 'ERROR: Percentage cannot be negative';
        DBMS_OUTPUT.PUT_LINE(v_log_message);
        RETURN;
    END IF;
    
    -- Check if employee exists
    SELECT Salary INTO v_salary
    FROM Employees
    WHERE EmployeeID = p_emp_id;
    
    -- Update employee salary
    UPDATE Employees
    SET Salary = Salary * (1 + p_percentage/100)
    WHERE EmployeeID = p_emp_id;
    
    -- Log successful update
    v_log_message := 'Successfully updated salary for employee ID ' || p_emp_id || 
                     ' by ' || p_percentage || '%. New salary: $' || 
                     TO_CHAR(v_salary * (1 + p_percentage/100), '999,999.99');
    DBMS_OUTPUT.PUT_LINE(v_log_message);
    
    COMMIT;
    
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        v_log_message := 'ERROR: Employee ID ' || p_emp_id || ' does not exist';
        DBMS_OUTPUT.PUT_LINE(v_log_message);
        
    WHEN OTHERS THEN
        ROLLBACK;
        v_log_message := 'ERROR: An unexpected error occurred: ' || SQLERRM;
        DBMS_OUTPUT.PUT_LINE(v_log_message);
END UpdateSalary;
/

-- Scenario 3: Ensure data integrity when adding a new customer
CREATE OR REPLACE PROCEDURE AddNewCustomer(
    p_customer_id IN NUMBER,
    p_name IN VARCHAR2,
    p_dob IN DATE,
    p_balance IN NUMBER
) AS
    v_log_message VARCHAR2(200);
    v_count NUMBER;
    e_duplicate_customer EXCEPTION;
    PRAGMA EXCEPTION_INIT(e_duplicate_customer, -1);  -- ORA-00001: unique constraint violated
BEGIN
    -- Check if customer already exists
    SELECT COUNT(*) INTO v_count
    FROM Customers
    WHERE CustomerID = p_customer_id;
    
    IF v_count > 0 THEN
        RAISE e_duplicate_customer;
    END IF;
    
    -- Insert new customer
    INSERT INTO Customers (CustomerID, Name, DOB, Balance, LastModified)
    VALUES (p_customer_id, p_name, p_dob, p_balance, SYSDATE);
    
    -- Log successful insertion
    v_log_message := 'Successfully added new customer: ' || p_name || 
                     ' (ID: ' || p_customer_id || ') with balance: $' || p_balance;
    DBMS_OUTPUT.PUT_LINE(v_log_message);
    
    COMMIT;
    
EXCEPTION
    WHEN e_duplicate_customer THEN
        v_log_message := 'ERROR: Customer ID ' || p_customer_id || ' already exists';
        DBMS_OUTPUT.PUT_LINE(v_log_message);
        
    WHEN OTHERS THEN
        ROLLBACK;
        v_log_message := 'ERROR: An unexpected error occurred: ' || SQLERRM;
        DBMS_OUTPUT.PUT_LINE(v_log_message);
END AddNewCustomer;
/ 