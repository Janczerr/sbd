--PL/SQL

-- Odpowiedz do zad 1 --

CREATE OR REPLACE PROCEDURE zatowarowanie (v_nazwa VARCHAR, v_stan INT, v_cena NUMBER)
IS
    v_nazwa_i_cena NUMBER;
    v_max_indeks NUMBER;
BEGIN
    SELECT COUNT(*) INTO v_nazwa_i_cena FROM magazyn WHERE nazwa = v_nazwa AND cena = v_cena;
    SELECT MAX(idpozycji) INTO v_max_indeks FROM magazyn;
    IF v_nazwa_i_cena > 0 THEN
        DBMS_OUTPUT.PUT_LINE('Produkt istnieje w bazie, zwiększam stan magazynowy');
        UPDATE MAGAZYN SET stan = stan + v_stan WHERE nazwa = v_nazwa AND cena = v_cena;       
    ELSE
        DBMS_OUTPUT.PUT_LINE('Produkt nie istnieje w bazie, dodaje pozycje');
        INSERT INTO MAGAZYN VALUES (v_max_indeks + 1, v_nazwa, v_cena, v_stan);       
    END IF;
END;

-- Odpowiedz do zad 2 --

CREATE OR REPLACE TRIGGER zad_2
BEFORE UPDATE OR INSERT ON magazyn
FOR EACH ROW
BEGIN
    IF :new.stan < 0 THEN
        RAISE_APPLICATION_ERROR(-20001, 'Stan magazynowy nie moze byc ujemny');
    ELSIF :new.cena > :old.cena*1.05 THEN
        RAISE_APPLICATION_ERROR(-20001, 'Cena nie moze wzrosnac o wiecej niz 5%');
    ELSIF :new.cena < 1 THEN
        RAISE_APPLICATION_ERROR(-20001, 'Cena nie moze byc ujemna lub wynosic 0');
    END IF;
END;

--T/SQL

Napisz prosty program w Transact-SQL. Zadeklaruj zmienną, przypisz na tą zmienną liczbę 
rekordów w tabeli Emp (lub jakiejkolwiek innej) i wypisz uzyskany wynik używając instrukcji 
PRINT, w postaci napisu np. "W tabeli jest 10 osób".

DECLARE @var INT;
SET @var = 12;
--PRINT @var;
SELECT @var = COUNT(1) FROM emp;
--PRINT @var;
--SELECT TOP 3 @var = empno FROM emp;

SET @var = (SELECT COUNT(1) FROM emp);

PRINT 'There are ' + CAST(@var AS VARCHAR) + ' employees.';
PRINT 'There are ' + CONVERT(VARCHAR, @var) + ' employees.';

---

Używając Transact-SQL, policz liczbę pracowników z tabeli EMP. Jeśli liczba jest mniejsza niż 
16, wstaw pracownika Kowalskiego i wypisz komunikat. W przeciwnym przypadku wypisz 
komunikat informujący o tym, że nie wstawiono danych.

IF (SELECT COUNT(1) FROM Emp) <16
	BEGIN
		DECLARE @newId INTEGER, @currentDate DATE = GETDATE();

		SELECT @newId = MAX(e.Empno)+1 FROM Emp e;
		INSERT INTO EMP(Empno,Ename,Job,Mgr,Hiredate,Sal,Comm,Deptno)
		VALUES (@newId, 'New', 'Employee', NULL, @currentDate, 3000, NULL, 10);
		PRINT 'Employee ' + CAST(@newId AS VARCHAR) + ' hired with current date ('+CONVERT(VARCHAR, @currentDate, 104)+').';
	END;
ELSE 
	BEGIN
		PRINT 'There are already enough employees';
	END;

GO

---

Napisz procedurę zwracającą pracowników, którzy zarabiają więcej niż wartość zadana
parametrem procedury.

ALTER PROCEDURE FindEmployees
	@minimumSalary MONEY
AS
BEGIN	
	SET NOCOUNT ON;
	
	SELECT *
	FROM emp e 
	WHERE e.sal > @minimumSalary;
END

GO


EXECUTE FindEmployees 1500;
EXEC FindEmployees 1500;
EXEC FindEmployees @minimumSalary = 1500;

GO

---

Napisz procedurę służącą do wstawiania działów do tabeli Dept. Procedura będzie pobierać 
jako parametry: nr_działu, nazwę i lokalizację. Należy sprawdzić, czy dział o takiej nazwie lub 
lokalizacji już istnieje. Jeżeli istnieje, to nie wstawiamy nowego rekordu.

ALTER PROCEDURE AddDept 	
	@Name VARCHAR(50),
	@Location VARCHAR(50),
	@Deptno INT OUT
AS
BEGIN
	SET NOCOUNT ON;

	IF EXISTS (SELECT 1 FROM dept d WHERE d.dname = @Name OR d.loc = @Location)
		BEGIN
			RAISERROR ('Department already exists!',11,-1); 
			/*
			RAISERROR ('wiadomosc', -- Tekst komunikatu.  
			11, -- Severity,  
			-1  -- State, 
			);   
		   */
			--Znaczenie severity
			--https://docs.microsoft.com/en-us/sql/t-sql/language-elements/raiserror-transact-sql?view=sql-server-ver15#remarks
		END;
    ELSE
		BEGIN
			SET @Deptno = (SELECT MAX(Deptno) + 1 FROM Dept);
			INSERT INTO DEPT(Deptno, Dname, Loc) VALUES (@Deptno, @Name, @Location);
			PRINT 'Department ' + @Name + ' created.';
		END;	
END

GO

DECLARE @newId INT;
EXEC AddDept 'NewDept2', @Deptno = @newId OUT, @Location = 'Warsaw';
SELECT @newId AS NewDeptno;

GO

---

Napisz procedurę umożliwiającą użytkownikowi wprowadzanie nowych pracowników do 
tabeli EMP. Jako parametry będziemy podawać nazwisko i nr działu zatrudnianego 
pracownika. Procedura powinna wprowadzając nowy rekord sprawdzić, czy wprowadzany 
dział istnieje (jeżeli nie, to należy zgłosić błąd) oraz obliczyć mu pensję równą minimalnemu 
zarobkowi w tym dziale. EMPNO nowego pracownika powinno zostać wyliczone jako 
najwyższa istniejąca wartość w tabeli + 1.

ALTER PROCEDURE AddEmp 
	@Dname VARCHAR(50),
	@Ename VARCHAR(50)
AS
BEGIN
	SET NOCOUNT ON;
--	IF  (SELECT COUNT(1) FROM dept d WHERE d.dname = @Dname) <> 1
	IF NOT (SELECT COUNT(1) FROM dept d WHERE d.dname = @Dname) = 1
		BEGIN
			RAISERROR ('Department doesn''t exist!',11,-1);
		END;
    ELSE
		BEGIN
			DECLARE @Empno INT, @Deptno INT, @Salary MONEY, @Job VARCHAR(50);--deklaracja zmiennych
			
			SET @Empno = (SELECT MAX(empno) FROM emp) + 1 ;--przypisanie wartości do 1. zmiennej
			SET @Deptno = (SELECT d.deptno FROM dept d WHERE d.dname = @Dname);
			SELECT @Salary = ISNULL(AVG(e.sal),1000) FROM emp e WHERE e.deptno = @Deptno;--przypisanie wartości do 3. zmiennej korzystając z innego sposobu niż wcześniej
							 --ISNULL() w MSSQL to ekwiwalent Oracle'owego NVL()
			SELECT TOP 1 @Job = e.job	/*	1. jeżeli istnieje jakakolwiek szansa, że SELECT może zwrócić więcej niż 1 rekord nie powinniśmy używać SET (w celu uniknięcia błędów)
											2. TOP 3 zwraca 3 pierwsze rekordy z góry ze zbioru wynikowego */ 
			FROM emp e 
			GROUP BY e.job
			HAVING COUNT(1) = (	SELECT MAX(sub.num)
								FROM (SELECT COUNT(1) AS num, e2.job
									  FROM emp e2
									  GROUP BY e2.job) AS sub
								);
			
			
			INSERT INTO EMP(Empno,Ename,Job,Hiredate,Sal,Deptno)
		    VALUES (@Empno, @Ename, @Job, GETDATE(), @Salary, @Deptno);
			
			--Wyświetlenie wiadomości jako pojedynczy string w ResultSet
			SELECT 'New ' + @Job + ' has been hired (' +@Ename+'). Initial earnings: '
			+ CONVERT(VARCHAR, @Salary, 1) AS Information;
		END;	
END

GO

--Test
EXEC AddEmp @Dname = 'NewDept2', @Ename='Yoshi';

GO

---

Przy pomocy kursora przejrzyj wszystkich pracowników i zmodyfikuj wynagrodzenia tak, aby 
osoby zarabiające mniej niż 1000 miały zwiększone wynagrodzenie o 10%, natomiast osoby 
zarabiające powyżej 1500 miały zmniejszone wynagrodzenie o 10%. Wypisz na ekran każdą 
wprowadzoną zmianę.

DECLARE cur CURSOR FOR
	SELECT e.empno, e.sal
	FROM emp e;
DECLARE @empno INT, @sal MONEY;

OPEN cur;
PRINT '@@Fetch_status value BEFORE the first fetch: ' + CAST(@@Fetch_status AS VARCHAR);
FETCH NEXT FROM cur INTO @empno, @sal;
PRINT '@@Fetch_status value AFTER the first fetch: ' + CAST(@@Fetch_status AS VARCHAR);

WHILE @@Fetch_status = 0
	BEGIN
		PRINT 'processing ' + CAST(@empno AS VARCHAR)+' '+CAST(@sal AS VARCHAR);			
		IF @sal > 1500
			BEGIN
				UPDATE emp
				SET sal = sal * 0.9
				WHERE empno = @empno;
				PRINT 'Salary of the employee '+CAST(@empno AS VARCHAR)+' has been decreased to '+CAST(@sal * 0.9 AS VARCHAR);
			END;
		ELSE IF @sal < 1000
			BEGIN
				UPDATE emp
				SET sal = sal * 1.1
				WHERE empno = @empno;
				PRINT 'Salary of the employee '+CAST(@empno AS VARCHAR)+' has been increased to '+CAST(@sal * 1.1 AS VARCHAR);
			END;
		FETCH NEXT FROM cur INTO @empno, @sal;
	END;
PRINT '@@Fetch_status value AFTER the LAST fetch: ' + CAST(@@Fetch_status AS VARCHAR);
CLOSE cur;
DEALLOCATE cur;
GO

---

W procedurze sprawdź średnią wartość zarobków z tabeli EMP z działu określonego 
parametrem procedury. Następnie należy dać prowizję (comm) tym pracownikom tego 
działu, którzy zarabiają poniżej średniej. Prowizja powinna wynosić 5% ich miesięcznego 
wynagrodzenia.

CREATE PROCEDURE [dbo].[task3]
	@idDept INT
	AS
BEGIN
	SET NOCOUNT ON;
		DECLARE @avg MONEY = (	SELECT  AVG(e.sal)
								FROM emp e
								WHERE e.deptno=@idDept);

		DECLARE cur CURSOR FOR
			SELECT e.empno, e.sal
			FROM   emp e
			WHERE e.deptno=@idDept;
		DECLARE @empno   INT
			  , @sal   MONEY;

		OPEN cur;
		FETCH NEXT FROM cur INTO @empno, @sal;
		WHILE @@Fetch_status = 0
			BEGIN
				IF @sal < @avg
					BEGIN 
						UPDATE emp SET comm = sal*0.05 WHERE empno =@empno;
						PRINT 'Employee with number ' + CAST(@empno AS VARCHAR) + ' received a commssion.';
					END
				FETCH NEXT FROM cur INTO @empno, @sal;	
			END;
		CLOSE cur;
		DEALLOCATE cur;
END

GO

exec task3 10;


GO

---

(bez kursora) Utwórz tabelę Magazyn (IdPozycji, Nazwa, Ilosc) zawierającą ilości 
poszczególnych towarów w magazynie i wstaw do niej kilka przykładowych rekordów.
W bloku Transact-SQL sprawdź, którego artykułu jest najwięcej w magazynie i zmniejsz ilość 
tego artykułu o 5 (jeśli stan jest większy lub równy 5, w przeciwnym wypadku zgłoś błąd).

CREATE TABLE Warehouse 
             (IdItem	  INT IDENTITY,
             ItemName     VARCHAR(250) NOT NULL,
             Quantity     INT NOT NULL);

ALTER TABLE Warehouse
ADD CONSTRAINT Warehouse_PK PRIMARY KEY(IdItem);

INSERT INTO Warehouse (ItemName, Quantity)
VALUES ('Product 1', 10),
       ('Product 2', 30),
       ('Product 3', 35);

GO

ALTER FUNCTION fn_task4()
RETURNS VARCHAR(50)
BEGIN
	DECLARE @idItem INT, @itemName VARCHAR(50), @quantity INT;
		
	SELECT TOP 1 @idItem = w.IdItem, @itemName = w.ItemName, @quantity = w.Quantity
	FROM Warehouse w
	WHERE w.Quantity = (SELECT MAX(Quantity) FROM Warehouse);

	IF @quantity < 5
		RETURN NULL;

	RETURN @itemName;
END
GO

---

Przerób kod z zadania 4 na procedurę, której będziemy mogli podać wartość, o którą 
zmniejszamy stan (zamiast wpisanego „na sztywno” 5).

UPDATE Warehouse 
SET Quantity = Quantity - 5 
WHERE ItemName = dbo.fn_task4();

---

Utwórz wyzwalacz, który nie pozwoli usunąć rekordu z tabeli Emp.

GO
CREATE TRIGGER t_zad1 ON EMP
FOR DELETE
AS
     ROLLBACK;


--test
delete from emp;

---

Utwórz wyzwalacz, który przy wstawianiu pracownika do tabeli Emp, wstawi prowizję równą 
0, jeśli prowizja była pusta. Uwaga: Zadanie da się wykonać bez użycia wyzwalaczy przy 
pomocy DEFAULT. Użyjmy jednak wyzwalacza w celach treningowych.


CREATE TRIGGER t_zad2 ON EMP
AFTER INSERT
AS
     IF EXISTS(
     SELECT 1
     FROM   inserted AS i
     WHERE  i.comm IS NULL)
         BEGIN
             UPDATE     emp
                    SET
                        comm = 0
             WHERE      empno IN(SELECT i.empno
								 FROM         inserted AS i
								 WHERE  comm IS NULL);
     END;

---

Utwórz wyzwalacz, który przy wstawianiu lub modyfikowaniu danych w tabeli Emp sprawdzi 
czy nowe zarobki (wstawiane lub modyfikowane) są większe niż 1000. W przeciwnym 
przypadku wyzwalacz powinien zgłosić błąd i nie dopuścić do wstawienia rekordu. Uwaga: 
Ten sam efekt można uzyskać łatwiej przy pomocy więzów spójności typu CHECK. Użyjmy 
wyzwalacza w celach treningowych.

CREATE TRIGGER t_zad3
   ON  emp
   AFTER INSERT, UPDATE
AS 
BEGIN
	SET NOCOUNT ON;

   
	IF EXISTS(SELECT 1
			  FROM   inserted AS i
			  WHERE  i.sal <= 1000)
         BEGIN
            RAISERROR ('Pensja musi być wyższa niż 1000!', 15, 1);
			ROLLBACK;
		 END

END
GO

---

Utwórz tabelę budzet:
CREATE TABLE budzet (wartosc INT NOT NULL)
W tabeli tej będzie przechowywana łączna wartość wynagrodzenia wszystkich pracowników. 
Tabela będzie zawsze zawierała jeden wiersz. Należy najpierw obliczyć początkową wartość 
zarobków:
INSERT INTO budzet (wartosc)
SELECT SUM(sal) FROM emp
Utwórz wyzwalacz, który będzie pilnował, aby wartość w tabeli budzet była zawsze aktualna, 
a więc przy wszystkich operacjach aktualizujących tabelę emp (INSERT, UPDATE, DELETE), 
wyzwalacz będzie aktualizował wpis w tabeli budżet

CREATE TRIGGER t_zad4 ON EMP
FOR INSERT, UPDATE, DELETE
AS
     SET NOCOUNT ON;
     DECLARE @add INT = 0
           , @substract INT = 0;

	 -- nowe rekordy
	 SELECT @add=SUM(i.sal) FROM inserted i;
	 SELECT @substract=SUM(d.sal) FROM deleted d;     
	 UPDATE Budzet SET wartosc = wartosc + ISNULL(@add,0) - ISNULL(@substract,0);

---

Napisz wyzwalacz, który nie pozwoli modyfikować nazw działów w tabeli dept. Powinno być 
jednak możliwe wstawianie nowych działów.

CREATE TRIGGER t_zad5 ON dept
FOR UPDATE
AS
     SET NOCOUNT ON;
    
	IF EXISTS (SELECT 1 FROM inserted i JOIN deleted d ON i.DEPTNO=d.DEPTNO WHERE i.DNAME<>d.DNAME)
		BEGIN
			RAISERROR ('Nie można edytować nazw działów!', 15, 1);
			ROLLBACK;
		END

---

Napisz jeden wyzwalacz, który:
• Nie pozwoli usunąć pracownika, którego pensja jest większa od 0.
• Nie pozwoli zmienić nazwiska pracownika.
• Nie pozwoli wstawić pracownika, który już istnieje (sprawdzając po nazwisku).

CREATE TRIGGER t_zad6 ON emp
FOR INSERT, UPDATE, DELETE
AS
     SET NOCOUNT ON;
    
	IF EXISTS (SELECT 1 
				FROM inserted i RIGHT JOIN deleted d ON i.EMPNO=d.EMPNO 
				WHERE i.EMPNO IS NULL AND d.SAL>0) --rekordy usunięte (występujące wyłącznie w deleted) z pensją większą niż 0
		BEGIN
			RAISERROR ('Nie można usunąć pracownika z pensją wyższą niż 0', 15, 1);
			ROLLBACK;
		END

	IF EXISTS (SELECT 1 
				FROM inserted i JOIN deleted d ON i.EMPNO=d.EMPNO 
				WHERE i.ENAME<>d.ENAME) --rekordy zaktualizowane ze zmienionym nazwiskiem
		BEGIN
			RAISERROR ('Nie można zmieniać nazwisk pracowników!', 15, 1);
			ROLLBACK;
		END

	IF EXISTS (SELECT 1 --dodane rekordy z nazwiskami które istnieją w tabeli emp
				FROM inserted i LEFT JOIN deleted d ON i.EMPNO=d.EMPNO 
				WHERE d.EMPNO IS NULL AND EXISTS (SELECT 1 
													FROM EMP e 
													WHERE e.ENAME = i.ENAME AND e.EMPNO<> i.EMPNO)) 
													
		BEGIN
			RAISERROR ('Istnieje już pracownik z takim nazwiskiem!', 15, 1);
			ROLLBACK;
		END
