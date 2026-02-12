
/*
=============================================================
Create Database and Schemas
=============================================================
Script Purpose:
    This script creates a new database named 'data_warehouse' after checking if it already exists. 
    If the database exists, it is dropped and recreated. Additionally, the script sets up three schemas 
    within the database: 'stg0', 'stage', and 'report'.
	
WARNING:
    Running this script will drop the entire 'data_warehouse' database if it exists. 
    All data in the database will be permanently deleted. Proceed with caution 
    and ensure you have proper backups before running this script.
*/

USE master;

-- Drop and recreate the 'DataWarehouse' database
IF EXISTS (SELECT 1 FROM sys.databases WHERE name = 'data_warehouse')
BEGIN
    ALTER DATABASE data_warehouse SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE data_warehouse;
END;
GO

-- Create the 'data_warehouse' database
CREATE DATABASE data_warehouse;

Use data_warehouse;

-- Create Schemas
CREATE SCHEMA stg0;
GO

CREATE SCHEMA stage;
GO

CREATE SCHEMA report;
GO