-- =============================================
-- Create Schemas for Data Warehouse
-- =============================================
-- This script creates the logical schemas for organizing database objects

USE [EnterpriseDW];
GO

-- Staging schema for raw data ingestion
IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'staging')
BEGIN
    EXEC('CREATE SCHEMA staging');
    PRINT 'Schema [staging] created successfully';
END
ELSE
BEGIN
    PRINT 'Schema [staging] already exists';
END
GO

-- Dimension schema for dimension tables
IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'dim')
BEGIN
    EXEC('CREATE SCHEMA dim');
    PRINT 'Schema [dim] created successfully';
END
ELSE
BEGIN
    PRINT 'Schema [dim] already exists';
END
GO

-- Fact schema for fact tables
IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'fact')
BEGIN
    EXEC('CREATE SCHEMA fact');
    PRINT 'Schema [fact] created successfully';
END
ELSE
BEGIN
    PRINT 'Schema [fact] already exists';
END
GO

-- ETL schema for ETL control and logging
IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'etl')
BEGIN
    EXEC('CREATE SCHEMA etl');
    PRINT 'Schema [etl] created successfully';
END
ELSE
BEGIN
    PRINT 'Schema [etl] already exists';
END
GO

-- Views schema for reporting views
IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'views')
BEGIN
    EXEC('CREATE SCHEMA views');
    PRINT 'Schema [views] created successfully';
END
ELSE
BEGIN
    PRINT 'Schema [views] already exists';
END
GO

PRINT 'All schemas created successfully';
GO
