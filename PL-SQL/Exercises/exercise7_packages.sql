-- Exercise 7: Packages

-- Scenario 1: Package for customer management
CREATE OR REPLACE PACKAGE CustomerManagement AS
    -- Procedure to add a new customer
    PROCEDURE AddCustomer(
        p_customer_id IN NUMBER,
        p_name IN VARCHAR2,
        p_dob IN DATE,
        p_balance IN NUMBER
    );
    
    -- Procedure to update customer details
    PROCEDURE UpdateCustomer(
        p_customer_id IN NUMBER,
        p_name IN VARCHAR2 DEFAULT NULL,
        p_dob IN DATE DEFAULT NULL,
        p_balance IN NUMBER DEFAULT NULL
    );
    
    -- Function to get customer balance
    FUNCTION GetCustomerBalance(
        p_customer_id IN NUMBER
    ) RETURN NUMBER;
    
    -- Function to check if a customer exists
    FUNCTION CustomerExists(
        p_customer_id IN NUMBER
    ) RETURN BOOLEAN;
END CustomerManagement;
/

-- Package body implementation
CREATE OR REPLACE PACKAGE BODY CustomerManagement AS
    -- Procedure to add a new customer
    PROCEDURE AddCustomer(
        p_customer_id IN NUMBER,
        p_name IN VARCHAR2,
        p_dob IN DATE,
        p_balance IN NUMBER
    ) AS
        v_exists BOOLEAN;
    BEGIN
        -- Check if customer already exists
        v_exists := CustomerExists(p_customer_id);
        
        IF v_exists THEN
            RAISE_APPLICATION_ERROR(-20001, 'Customer ID ' || p_customer_id || ' already exists.');
        END IF;
        
        -- Insert new customer
        INSERT INTO Customers (CustomerID, Name, DOB, Balance, LastModified)
        VALUES (p_customer_id, p_name, p_dob, p_balance, SYSDATE);
        
        COMMIT;
        DBMS_OUTPUT.PUT_LINE('Customer ' || p_name || ' added successfully.');
    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            DBMS_OUTPUT.PUT_LINE('Error adding customer: ' || SQLERRM);
    END AddCustomer;
    
    -- Procedure to update customer details
    PROCEDURE UpdateCustomer(
        p_customer_id IN NUMBER,
        p_name IN VARCHAR2 DEFAULT NULL,
        p_dob IN DATE DEFAULT NULL,
        p_balance IN NUMBER DEFAULT NULL
    ) AS
        v_exists BOOLEAN;
        v_name Customers.Name%TYPE;
        v_dob Customers.DOB%TYPE;
        v_balance Customers.Balance%TYPE;
    BEGIN
        -- Check if customer exists
        v_exists := CustomerExists(p_customer_id);
        
        IF NOT v_exists THEN
            RAISE_APPLICATION_ERROR(-20002, 'Customer ID ' || p_customer_id || ' does not exist.');
        END IF;
        
        -- Get current customer details
        SELECT Name, DOB, Balance
        INTO v_name, v_dob, v_balance
        FROM Customers
        WHERE CustomerID = p_customer_id;
        
        -- Update only the provided fields
        UPDATE Customers
        SET Name = NVL(p_name, v_name),
            DOB = NVL(p_dob, v_dob),
            Balance = NVL(p_balance, v_balance),
            LastModified = SYSDATE
        WHERE CustomerID = p_customer_id;
        
        COMMIT;
        DBMS_OUTPUT.PUT_LINE('Customer ID ' || p_customer_id || ' updated successfully.');
    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            DBMS_OUTPUT.PUT_LINE('Error updating customer: ' || SQLERRM);
    END UpdateCustomer;
    
    -- Function to get customer balance
    FUNCTION GetCustomerBalance(
        p_customer_id IN NUMBER
    ) RETURN NUMBER IS
        v_balance NUMBER;
    BEGIN
        SELECT Balance INTO v_balance
        FROM Customers
        WHERE CustomerID = p_customer_id;
        
        RETURN v_balance;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE_APPLICATION_ERROR(-20003, 'Customer ID ' || p_customer_id || ' does not exist.');
            RETURN NULL;
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('Error retrieving customer balance: ' || SQLERRM);
            RETURN NULL;
    END GetCustomerBalance;
    
    -- Function to check if a customer exists
    FUNCTION CustomerExists(
        p_customer_id IN NUMBER
    ) RETURN BOOLEAN IS
        v_count NUMBER;
    BEGIN
        SELECT COUNT(*) INTO v_count
        FROM Customers
        WHERE CustomerID = p_customer_id;
        
        RETURN v_count > 0;
    EXCEPTION
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('Error checking customer existence: ' || SQLERRM);
            RETURN FALSE;
    END CustomerExists;
END CustomerManagement;
/

-- Scenario 2: Package for employee management
CREATE OR REPLACE PACKAGE EmployeeManagement AS
    -- Procedure to hire a new employee
    PROCEDURE HireEmployee(
        p_employee_id IN NUMBER,
        p_name IN VARCHAR2,
        p_position IN VARCHAR2,
        p_salary IN NUMBER,
        p_department IN VARCHAR2
    );
    
    -- Procedure to update employee details
    PROCEDURE UpdateEmployee(
        p_employee_id IN NUMBER,
        p_position IN VARCHAR2 DEFAULT NULL,
        p_salary IN NUMBER DEFAULT NULL,
        p_department IN VARCHAR2 DEFAULT NULL
    );
    
    -- Procedure to terminate an employee
    PROCEDURE TerminateEmployee(
        p_employee_id IN NUMBER
    );
    
    -- Function to calculate annual salary including bonuses
    FUNCTION CalculateAnnualSalary(
        p_employee_id IN NUMBER,
        p_bonus_percentage IN NUMBER DEFAULT 0
    ) RETURN NUMBER;
    
    -- Function to check if an employee exists
    FUNCTION EmployeeExists(
        p_employee_id IN NUMBER
    ) RETURN BOOLEAN;
END EmployeeManagement;
/

-- Package body implementation
CREATE OR REPLACE PACKAGE BODY EmployeeManagement AS
    -- Procedure to hire a new employee
    PROCEDURE HireEmployee(
        p_employee_id IN NUMBER,
        p_name IN VARCHAR2,
        p_position IN VARCHAR2,
        p_salary IN NUMBER,
        p_department IN VARCHAR2
    ) AS
        v_exists BOOLEAN;
    BEGIN
        -- Check if employee already exists
        v_exists := EmployeeExists(p_employee_id);
        
        IF v_exists THEN
            RAISE_APPLICATION_ERROR(-20101, 'Employee ID ' || p_employee_id || ' already exists.');
        END IF;
        
        -- Insert new employee
        INSERT INTO Employees (EmployeeID, Name, Position, Salary, Department, HireDate)
        VALUES (p_employee_id, p_name, p_position, p_salary, p_department, SYSDATE);
        
        COMMIT;
        DBMS_OUTPUT.PUT_LINE('Employee ' || p_name || ' hired successfully.');
    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            DBMS_OUTPUT.PUT_LINE('Error hiring employee: ' || SQLERRM);
    END HireEmployee;
    
    -- Procedure to update employee details
    PROCEDURE UpdateEmployee(
        p_employee_id IN NUMBER,
        p_position IN VARCHAR2 DEFAULT NULL,
        p_salary IN NUMBER DEFAULT NULL,
        p_department IN VARCHAR2 DEFAULT NULL
    ) AS
        v_exists BOOLEAN;
        v_position Employees.Position%TYPE;
        v_salary Employees.Salary%TYPE;
        v_department Employees.Department%TYPE;
    BEGIN
        -- Check if employee exists
        v_exists := EmployeeExists(p_employee_id);
        
        IF NOT v_exists THEN
            RAISE_APPLICATION_ERROR(-20102, 'Employee ID ' || p_employee_id || ' does not exist.');
        END IF;
        
        -- Get current employee details
        SELECT Position, Salary, Department
        INTO v_position, v_salary, v_department
        FROM Employees
        WHERE EmployeeID = p_employee_id;
        
        -- Update only the provided fields
        UPDATE Employees
        SET Position = NVL(p_position, v_position),
            Salary = NVL(p_salary, v_salary),
            Department = NVL(p_department, v_department)
        WHERE EmployeeID = p_employee_id;
        
        COMMIT;
        DBMS_OUTPUT.PUT_LINE('Employee ID ' || p_employee_id || ' updated successfully.');
    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            DBMS_OUTPUT.PUT_LINE('Error updating employee: ' || SQLERRM);
    END UpdateEmployee;
    
    -- Procedure to terminate an employee
    PROCEDURE TerminateEmployee(
        p_employee_id IN NUMBER
    ) AS
        v_exists BOOLEAN;
        v_name Employees.Name%TYPE;
    BEGIN
        -- Check if employee exists
        v_exists := EmployeeExists(p_employee_id);
        
        IF NOT v_exists THEN
            RAISE_APPLICATION_ERROR(-20103, 'Employee ID ' || p_employee_id || ' does not exist.');
        END IF;
        
        -- Get employee name for the message
        SELECT Name INTO v_name
        FROM Employees
        WHERE EmployeeID = p_employee_id;
        
        -- Delete the employee record
        DELETE FROM Employees
        WHERE EmployeeID = p_employee_id;
        
        COMMIT;
        DBMS_OUTPUT.PUT_LINE('Employee ' || v_name || ' (ID: ' || p_employee_id || ') terminated successfully.');
    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            DBMS_OUTPUT.PUT_LINE('Error terminating employee: ' || SQLERRM);
    END TerminateEmployee;
    
    -- Function to calculate annual salary including bonuses
    FUNCTION CalculateAnnualSalary(
        p_employee_id IN NUMBER,
        p_bonus_percentage IN NUMBER DEFAULT 0
    ) RETURN NUMBER IS
        v_monthly_salary Employees.Salary%TYPE;
        v_annual_salary NUMBER;
        v_bonus NUMBER;
    BEGIN
        -- Check if employee exists
        IF NOT EmployeeExists(p_employee_id) THEN
            RAISE_APPLICATION_ERROR(-20104, 'Employee ID ' || p_employee_id || ' does not exist.');
        END IF;
        
        -- Get employee monthly salary
        SELECT Salary INTO v_monthly_salary
        FROM Employees
        WHERE EmployeeID = p_employee_id;
        
        -- Calculate annual salary
        v_annual_salary := v_monthly_salary * 12;
        
        -- Add bonus if applicable
        IF p_bonus_percentage > 0 THEN
            v_bonus := v_annual_salary * (p_bonus_percentage / 100);
            v_annual_salary := v_annual_salary + v_bonus;
        END IF;
        
        RETURN v_annual_salary;
    EXCEPTION
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('Error calculating annual salary: ' || SQLERRM);
            RETURN NULL;
    END CalculateAnnualSalary;
    
    -- Function to check if an employee exists
    FUNCTION EmployeeExists(
        p_employee_id IN NUMBER
    ) RETURN BOOLEAN IS
        v_count NUMBER;
    BEGIN
        SELECT COUNT(*) INTO v_count
        FROM Employees
        WHERE EmployeeID = p_employee_id;
        
        RETURN v_count > 0;
    EXCEPTION
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('Error checking employee existence: ' || SQLERRM);
            RETURN FALSE;
    END EmployeeExists;
END EmployeeManagement;
/

-- Scenario 3: Package for account operations
CREATE OR REPLACE PACKAGE AccountOperations AS
    -- Procedure to open a new account
    PROCEDURE OpenAccount(
        p_account_id IN NUMBER,
        p_customer_id IN NUMBER,
        p_account_type IN VARCHAR2,
        p_initial_balance IN NUMBER DEFAULT 0
    );
    
    -- Procedure to close an account
    PROCEDURE CloseAccount(
        p_account_id IN NUMBER
    );
    
    -- Procedure to deposit funds into an account
    PROCEDURE Deposit(
        p_account_id IN NUMBER,
        p_amount IN NUMBER
    );
    
    -- Procedure to withdraw funds from an account
    PROCEDURE Withdraw(
        p_account_id IN NUMBER,
        p_amount IN NUMBER
    );
    
    -- Function to get total balance of a customer across all accounts
    FUNCTION GetTotalCustomerBalance(
        p_customer_id IN NUMBER
    ) RETURN NUMBER;
    
    -- Function to check if an account exists
    FUNCTION AccountExists(
        p_account_id IN NUMBER
    ) RETURN BOOLEAN;
END AccountOperations;
/

-- Package body implementation
CREATE OR REPLACE PACKAGE BODY AccountOperations AS
    -- Procedure to open a new account
    PROCEDURE OpenAccount(
        p_account_id IN NUMBER,
        p_customer_id IN NUMBER,
        p_account_type IN VARCHAR2,
        p_initial_balance IN NUMBER DEFAULT 0
    ) AS
        v_account_exists BOOLEAN;
        v_customer_exists BOOLEAN;
    BEGIN
        -- Check if account already exists
        v_account_exists := AccountExists(p_account_id);
        
        IF v_account_exists THEN
            RAISE_APPLICATION_ERROR(-20201, 'Account ID ' || p_account_id || ' already exists.');
        END IF;
        
        -- Check if customer exists
        SELECT COUNT(*) > 0 INTO v_customer_exists
        FROM Customers
        WHERE CustomerID = p_customer_id;
        
        IF NOT v_customer_exists THEN
            RAISE_APPLICATION_ERROR(-20202, 'Customer ID ' || p_customer_id || ' does not exist.');
        END IF;
        
        -- Validate initial balance
        IF p_initial_balance < 0 THEN
            RAISE_APPLICATION_ERROR(-20203, 'Initial balance cannot be negative.');
        END IF;
        
        -- Insert new account
        INSERT INTO Accounts (AccountID, CustomerID, AccountType, Balance, LastModified)
        VALUES (p_account_id, p_customer_id, p_account_type, p_initial_balance, SYSDATE);
        
        -- If initial balance is greater than 0, create a deposit transaction
        IF p_initial_balance > 0 THEN
            INSERT INTO Transactions (TransactionID, AccountID, TransactionDate, Amount, TransactionType)
            VALUES (TransactionID.NEXTVAL, p_account_id, SYSDATE, p_initial_balance, 'Deposit');
        END IF;
        
        COMMIT;
        DBMS_OUTPUT.PUT_LINE('Account opened successfully for Customer ID ' || p_customer_id || 
                           ' with initial balance: $' || p_initial_balance);
    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            DBMS_OUTPUT.PUT_LINE('Error opening account: ' || SQLERRM);
    END OpenAccount;
    
    -- Procedure to close an account
    PROCEDURE CloseAccount(
        p_account_id IN NUMBER
    ) AS
        v_exists BOOLEAN;
        v_balance NUMBER;
        v_customer_id NUMBER;
    BEGIN
        -- Check if account exists
        v_exists := AccountExists(p_account_id);
        
        IF NOT v_exists THEN
            RAISE_APPLICATION_ERROR(-20204, 'Account ID ' || p_account_id || ' does not exist.');
        END IF;
        
        -- Get account balance and customer ID
        SELECT Balance, CustomerID INTO v_balance, v_customer_id
        FROM Accounts
        WHERE AccountID = p_account_id;
        
        -- If balance is not zero, transfer to customer's other account or raise error
        IF v_balance <> 0 THEN
            DECLARE
                v_other_account NUMBER;
            BEGIN
                -- Try to find another account of the same customer
                SELECT MIN(AccountID) INTO v_other_account
                FROM Accounts
                WHERE CustomerID = v_customer_id
                AND AccountID <> p_account_id;
                
                IF v_other_account IS NOT NULL THEN
                    -- Transfer balance to other account
                    UPDATE Accounts
                    SET Balance = Balance + v_balance,
                        LastModified = SYSDATE
                    WHERE AccountID = v_other_account;
                    
                    -- Zero out the closing account
                    UPDATE Accounts
                    SET Balance = 0,
                        LastModified = SYSDATE
                    WHERE AccountID = p_account_id;
                    
                    -- Record the transfer transaction
                    INSERT INTO Transactions (TransactionID, AccountID, TransactionDate, Amount, TransactionType)
                    VALUES (TransactionID.NEXTVAL, p_account_id, SYSDATE, v_balance, 'Withdrawal');
                    
                    INSERT INTO Transactions (TransactionID, AccountID, TransactionDate, Amount, TransactionType)
                    VALUES (TransactionID.NEXTVAL, v_other_account, SYSDATE, v_balance, 'Deposit');
                    
                    DBMS_OUTPUT.PUT_LINE('Remaining balance of $' || v_balance || 
                                       ' transferred to account ' || v_other_account);
                ELSE
                    RAISE_APPLICATION_ERROR(-20205, 'Cannot close account with non-zero balance. ' ||
                                                    'Balance: $' || v_balance || 
                                                    '. No other account available for transfer.');
                END IF;
            EXCEPTION
                WHEN NO_DATA_FOUND THEN
                    RAISE_APPLICATION_ERROR(-20205, 'Cannot close account with non-zero balance. ' ||
                                                    'Balance: $' || v_balance || 
                                                    '. No other account available for transfer.');
            END;
        END IF;
        
        -- Delete the account
        DELETE FROM Accounts
        WHERE AccountID = p_account_id;
        
        COMMIT;
        DBMS_OUTPUT.PUT_LINE('Account ID ' || p_account_id || ' closed successfully.');
    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            DBMS_OUTPUT.PUT_LINE('Error closing account: ' || SQLERRM);
    END CloseAccount;
    
    -- Procedure to deposit funds into an account
    PROCEDURE Deposit(
        p_account_id IN NUMBER,
        p_amount IN NUMBER
    ) AS
        v_exists BOOLEAN;
    BEGIN
        -- Validate amount
        IF p_amount <= 0 THEN
            RAISE_APPLICATION_ERROR(-20206, 'Deposit amount must be positive.');
        END IF;
        
        -- Check if account exists
        v_exists := AccountExists(p_account_id);
        
        IF NOT v_exists THEN
            RAISE_APPLICATION_ERROR(-20207, 'Account ID ' || p_account_id || ' does not exist.');
        END IF;
        
        -- Update account balance
        UPDATE Accounts
        SET Balance = Balance + p_amount,
            LastModified = SYSDATE
        WHERE AccountID = p_account_id;
        
        -- Record the transaction
        INSERT INTO Transactions (TransactionID, AccountID, TransactionDate, Amount, TransactionType)
        VALUES (TransactionID.NEXTVAL, p_account_id, SYSDATE, p_amount, 'Deposit');
        
        COMMIT;
        DBMS_OUTPUT.PUT_LINE('Successfully deposited $' || p_amount || ' into account ' || p_account_id);
    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            DBMS_OUTPUT.PUT_LINE('Error processing deposit: ' || SQLERRM);
    END Deposit;
    
    -- Procedure to withdraw funds from an account
    PROCEDURE Withdraw(
        p_account_id IN NUMBER,
        p_amount IN NUMBER
    ) AS
        v_exists BOOLEAN;
        v_balance NUMBER;
    BEGIN
        -- Validate amount
        IF p_amount <= 0 THEN
            RAISE_APPLICATION_ERROR(-20208, 'Withdrawal amount must be positive.');
        END IF;
        
        -- Check if account exists
        v_exists := AccountExists(p_account_id);
        
        IF NOT v_exists THEN
            RAISE_APPLICATION_ERROR(-20209, 'Account ID ' || p_account_id || ' does not exist.');
        END IF;
        
        -- Check if sufficient balance
        SELECT Balance INTO v_balance
        FROM Accounts
        WHERE AccountID = p_account_id;
        
        IF v_balance < p_amount THEN
            RAISE_APPLICATION_ERROR(-20210, 'Insufficient funds. Balance: $' || v_balance || 
                                        ', Requested: $' || p_amount);
        END IF;
        
        -- Update account balance
        UPDATE Accounts
        SET Balance = Balance - p_amount,
            LastModified = SYSDATE
        WHERE AccountID = p_account_id;
        
        -- Record the transaction
        INSERT INTO Transactions (TransactionID, AccountID, TransactionDate, Amount, TransactionType)
        VALUES (TransactionID.NEXTVAL, p_account_id, SYSDATE, p_amount, 'Withdrawal');
        
        COMMIT;
        DBMS_OUTPUT.PUT_LINE('Successfully withdrew $' || p_amount || ' from account ' || p_account_id);
    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            DBMS_OUTPUT.PUT_LINE('Error processing withdrawal: ' || SQLERRM);
    END Withdraw;
    
    -- Function to get total balance of a customer across all accounts
    FUNCTION GetTotalCustomerBalance(
        p_customer_id IN NUMBER
    ) RETURN NUMBER IS
        v_total_balance NUMBER := 0;
        v_customer_exists BOOLEAN;
    BEGIN
        -- Check if customer exists
        SELECT COUNT(*) > 0 INTO v_customer_exists
        FROM Customers
        WHERE CustomerID = p_customer_id;
        
        IF NOT v_customer_exists THEN
            RAISE_APPLICATION_ERROR(-20211, 'Customer ID ' || p_customer_id || ' does not exist.');
        END IF;
        
        -- Calculate total balance across all accounts
        SELECT NVL(SUM(Balance), 0) INTO v_total_balance
        FROM Accounts
        WHERE CustomerID = p_customer_id;
        
        RETURN v_total_balance;
    EXCEPTION
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('Error calculating total balance: ' || SQLERRM);
            RETURN NULL;
    END GetTotalCustomerBalance;
    
    -- Function to check if an account exists
    FUNCTION AccountExists(
        p_account_id IN NUMBER
    ) RETURN BOOLEAN IS
        v_count NUMBER;
    BEGIN
        SELECT COUNT(*) INTO v_count
        FROM Accounts
        WHERE AccountID = p_account_id;
        
        RETURN v_count > 0;
    EXCEPTION
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('Error checking account existence: ' || SQLERRM);
            RETURN FALSE;
    END AccountExists;
END AccountOperations;
/

-- Test the packages
SET SERVEROUTPUT ON;
BEGIN
    DBMS_OUTPUT.PUT_LINE('=== Testing CustomerManagement Package ===');
    DBMS_OUTPUT.PUT_LINE('Balance of Customer 1: $' || CustomerManagement.GetCustomerBalance(1));
    
    DBMS_OUTPUT.PUT_LINE('=== Testing EmployeeManagement Package ===');
    DBMS_OUTPUT.PUT_LINE('Annual Salary of Employee 1 with 10% bonus: $' || 
                        EmployeeManagement.CalculateAnnualSalary(1, 10));
    
    DBMS_OUTPUT.PUT_LINE('=== Testing AccountOperations Package ===');
    DBMS_OUTPUT.PUT_LINE('Total Balance for Customer 3: $' || 
                        AccountOperations.GetTotalCustomerBalance(3));
END;
/ 