"""
Pytest configuration and fixtures for Synapse API tests
"""

import pytest
import os
from dotenv import load_dotenv

# Load environment variables
load_dotenv()


@pytest.fixture(scope="session")
def synapse_config():
    """Provide Synapse configuration from environment variables"""
    return {
        "workspace_name": os.getenv("SYNAPSE_WORKSPACE_NAME", "your-workspace-name"),
        "subscription_id": os.getenv("AZURE_SUBSCRIPTION_ID", "your-subscription-id"),
        "resource_group": os.getenv("AZURE_RESOURCE_GROUP", "your-resource-group"),
        "tenant_id": os.getenv("AZURE_TENANT_ID", "your-tenant-id"),
        "sql_pool_name": os.getenv("SQL_POOL_NAME", "EnterpriseDW"),
        "spark_pool_name": os.getenv("SPARK_POOL_NAME", "sparkpool")
    }


@pytest.fixture(scope="session")
def sql_credentials():
    """Provide SQL credentials from environment variables"""
    return {
        "username": os.getenv("SQL_USERNAME", "sqladmin"),
        "password": os.getenv("SQL_PASSWORD", "")
    }


def pytest_configure(config):
    """Configure pytest with custom markers"""
    config.addinivalue_line(
        "markers", "integration: mark test as integration test"
    )
    config.addinivalue_line(
        "markers", "slow: mark test as slow running"
    )
    config.addinivalue_line(
        "markers", "requires_auth: mark test as requiring authentication"
    )
