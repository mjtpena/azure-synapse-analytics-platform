"""
Azure Synapse Analytics REST API Tests
Tests for workspace management, pipeline runs, and SQL queries
"""

import pytest
import requests
import json
import time
from datetime import datetime
from azure.identity import DefaultAzureCredential
from typing import Dict, Any


class SynapseAPIClient:
    """Client for interacting with Azure Synapse Analytics REST API"""

    def __init__(self, workspace_name: str, subscription_id: str, resource_group: str):
        self.workspace_name = workspace_name
        self.subscription_id = subscription_id
        self.resource_group = resource_group
        self.credential = DefaultAzureCredential()
        self.base_url = f"https://{workspace_name}.dev.azuresynapse.net"
        self.management_url = f"https://management.azure.com/subscriptions/{subscription_id}/resourceGroups/{resource_group}/providers/Microsoft.Synapse/workspaces/{workspace_name}"
        self.api_version = "2021-06-01"
        self.access_token = None

    def get_access_token(self, resource: str = "https://dev.azuresynapse.net") -> str:
        """Get Azure AD access token"""
        token = self.credential.get_token(f"{resource}/.default")
        return token.token

    def get_management_token(self) -> str:
        """Get Azure Management access token"""
        token = self.credential.get_token("https://management.azure.com/.default")
        return token.token

    def get_headers(self, use_management: bool = False) -> Dict[str, str]:
        """Get HTTP headers with authentication"""
        token = self.get_management_token() if use_management else self.get_access_token()
        return {
            "Authorization": f"Bearer {token}",
            "Content-Type": "application/json"
        }


class TestWorkspaceManagement:
    """Tests for Synapse workspace management APIs"""

    @pytest.fixture
    def client(self):
        """Create Synapse API client"""
        return SynapseAPIClient(
            workspace_name="your-workspace-name",
            subscription_id="your-subscription-id",
            resource_group="your-resource-group"
        )

    def test_get_workspace_info(self, client):
        """Test retrieving workspace information"""
        url = f"{client.management_url}?api-version={client.api_version}"
        response = requests.get(url, headers=client.get_headers(use_management=True))

        assert response.status_code == 200
        data = response.json()
        assert "properties" in data
        assert data["properties"]["defaultDataLakeStorage"] is not None
        print(f"Workspace Name: {data['name']}")
        print(f"Location: {data['location']}")

    def test_list_sql_pools(self, client):
        """Test listing SQL pools"""
        url = f"{client.management_url}/sqlPools?api-version={client.api_version}"
        response = requests.get(url, headers=client.get_headers(use_management=True))

        assert response.status_code == 200
        data = response.json()
        assert "value" in data

        for pool in data["value"]:
            print(f"SQL Pool: {pool['name']}, SKU: {pool['sku']['name']}")

    def test_list_spark_pools(self, client):
        """Test listing Spark pools"""
        url = f"{client.management_url}/bigDataPools?api-version={client.api_version}"
        response = requests.get(url, headers=client.get_headers(use_management=True))

        assert response.status_code == 200
        data = response.json()
        assert "value" in data

        for pool in data["value"]:
            print(f"Spark Pool: {pool['name']}, Node Size: {pool['properties']['nodeSize']}")

    def test_get_workspace_firewall_rules(self, client):
        """Test retrieving firewall rules"""
        url = f"{client.management_url}/firewallRules?api-version={client.api_version}"
        response = requests.get(url, headers=client.get_headers(use_management=True))

        assert response.status_code == 200
        data = response.json()
        assert "value" in data

        for rule in data["value"]:
            print(f"Firewall Rule: {rule['name']}")


class TestPipelineOperations:
    """Tests for Synapse pipeline operations"""

    @pytest.fixture
    def client(self):
        """Create Synapse API client"""
        return SynapseAPIClient(
            workspace_name="your-workspace-name",
            subscription_id="your-subscription-id",
            resource_group="your-resource-group"
        )

    def test_list_pipelines(self, client):
        """Test listing all pipelines"""
        url = f"{client.base_url}/pipelines?api-version=2020-12-01"
        response = requests.get(url, headers=client.get_headers())

        assert response.status_code == 200
        data = response.json()
        assert "value" in data

        for pipeline in data["value"]:
            print(f"Pipeline: {pipeline['name']}")

    def test_get_pipeline_details(self, client):
        """Test getting pipeline details"""
        pipeline_name = "pl_master_etl_pipeline"
        url = f"{client.base_url}/pipelines/{pipeline_name}?api-version=2020-12-01"
        response = requests.get(url, headers=client.get_headers())

        if response.status_code == 200:
            data = response.json()
            assert "properties" in data
            assert "activities" in data["properties"]
            print(f"Pipeline: {pipeline_name}, Activities: {len(data['properties']['activities'])}")

    def test_trigger_pipeline_run(self, client):
        """Test triggering a pipeline run"""
        pipeline_name = "pl_master_etl_pipeline"
        url = f"{client.base_url}/pipelines/{pipeline_name}/createRun?api-version=2020-12-01"

        payload = {
            "parameters": {
                "ProcessDate": datetime.now().strftime("%Y-%m-%d")
            }
        }

        response = requests.post(url, headers=client.get_headers(), json=payload)

        if response.status_code == 202 or response.status_code == 200:
            data = response.json()
            assert "runId" in data
            run_id = data["runId"]
            print(f"Pipeline run started: {run_id}")
            return run_id
        else:
            pytest.skip("Pipeline not found or cannot be triggered")

    def test_get_pipeline_run_status(self, client):
        """Test getting pipeline run status"""
        # First trigger a run
        run_id = self.test_trigger_pipeline_run(client)

        if run_id:
            url = f"{client.base_url}/pipelineruns/{run_id}?api-version=2020-12-01"

            # Poll for status
            max_attempts = 10
            for i in range(max_attempts):
                response = requests.get(url, headers=client.get_headers())
                assert response.status_code == 200

                data = response.json()
                status = data.get("status")
                print(f"Attempt {i+1}: Pipeline run status: {status}")

                if status in ["Succeeded", "Failed", "Cancelled"]:
                    break

                time.sleep(10)

    def test_list_pipeline_runs(self, client):
        """Test listing recent pipeline runs"""
        url = f"{client.base_url}/queryPipelineRuns?api-version=2020-12-01"

        payload = {
            "lastUpdatedAfter": (datetime.now().replace(hour=0, minute=0, second=0)).isoformat() + "Z",
            "lastUpdatedBefore": datetime.now().isoformat() + "Z"
        }

        response = requests.post(url, headers=client.get_headers(), json=payload)

        assert response.status_code == 200
        data = response.json()

        if "value" in data:
            for run in data["value"]:
                print(f"Run ID: {run['runId']}, Status: {run['status']}, Pipeline: {run['pipelineName']}")

    def test_cancel_pipeline_run(self, client):
        """Test cancelling a pipeline run"""
        # First trigger a run
        run_id = self.test_trigger_pipeline_run(client)

        if run_id:
            url = f"{client.base_url}/pipelineruns/{run_id}/cancel?api-version=2020-12-01"
            response = requests.post(url, headers=client.get_headers())

            # 200 or 404 are acceptable (404 if already completed)
            assert response.status_code in [200, 404]


class TestSQLPoolQueries:
    """Tests for SQL Pool query operations"""

    @pytest.fixture
    def client(self):
        """Create Synapse API client"""
        return SynapseAPIClient(
            workspace_name="your-workspace-name",
            subscription_id="your-subscription-id",
            resource_group="your-resource-group"
        )

    def test_execute_sql_query(self, client):
        """Test executing a SQL query"""
        # Note: This requires additional setup with SQL authentication
        sql_pool_name = "EnterpriseDW"
        url = f"https://{client.workspace_name}.sql.azuresynapse.net/{sql_pool_name}"

        # This is a placeholder - actual implementation requires SQL authentication
        print(f"SQL Pool Endpoint: {url}")
        pytest.skip("SQL authentication setup required")

    def test_check_sql_pool_status(self, client):
        """Test checking SQL pool status"""
        sql_pool_name = "EnterpriseDW"
        url = f"{client.management_url}/sqlPools/{sql_pool_name}?api-version={client.api_version}"

        response = requests.get(url, headers=client.get_headers(use_management=True))

        if response.status_code == 200:
            data = response.json()
            status = data["properties"]["status"]
            print(f"SQL Pool Status: {status}")
            assert status in ["Online", "Paused", "Pausing", "Resuming"]

    def test_pause_sql_pool(self, client):
        """Test pausing SQL pool"""
        sql_pool_name = "EnterpriseDW"
        url = f"{client.management_url}/sqlPools/{sql_pool_name}/pause?api-version={client.api_version}"

        response = requests.post(url, headers=client.get_headers(use_management=True))

        # 200 or 202 indicates success
        if response.status_code in [200, 202]:
            print("SQL Pool pause initiated")
        else:
            print(f"SQL Pool pause failed or already paused: {response.status_code}")

    def test_resume_sql_pool(self, client):
        """Test resuming SQL pool"""
        sql_pool_name = "EnterpriseDW"
        url = f"{client.management_url}/sqlPools/{sql_pool_name}/resume?api-version={client.api_version}"

        response = requests.post(url, headers=client.get_headers(use_management=True))

        # 200 or 202 indicates success
        if response.status_code in [200, 202]:
            print("SQL Pool resume initiated")
        else:
            print(f"SQL Pool resume failed or already online: {response.status_code}")


class TestNotebookOperations:
    """Tests for Synapse notebook operations"""

    @pytest.fixture
    def client(self):
        """Create Synapse API client"""
        return SynapseAPIClient(
            workspace_name="your-workspace-name",
            subscription_id="your-subscription-id",
            resource_group="your-resource-group"
        )

    def test_list_notebooks(self, client):
        """Test listing all notebooks"""
        url = f"{client.base_url}/notebooks?api-version=2020-12-01"
        response = requests.get(url, headers=client.get_headers())

        assert response.status_code == 200
        data = response.json()

        if "value" in data:
            for notebook in data["value"]:
                print(f"Notebook: {notebook['name']}")

    def test_get_notebook_details(self, client):
        """Test getting notebook details"""
        notebook_name = "01_data_ingestion"
        url = f"{client.base_url}/notebooks/{notebook_name}?api-version=2020-12-01"
        response = requests.get(url, headers=client.get_headers())

        if response.status_code == 200:
            data = response.json()
            assert "properties" in data
            print(f"Notebook: {notebook_name}")


class TestIntegrationDatasets:
    """Tests for integration runtime and datasets"""

    @pytest.fixture
    def client(self):
        """Create Synapse API client"""
        return SynapseAPIClient(
            workspace_name="your-workspace-name",
            subscription_id="your-subscription-id",
            resource_group="your-resource-group"
        )

    def test_list_linked_services(self, client):
        """Test listing linked services"""
        url = f"{client.base_url}/linkedservices?api-version=2020-12-01"
        response = requests.get(url, headers=client.get_headers())

        assert response.status_code == 200
        data = response.json()

        if "value" in data:
            for service in data["value"]:
                print(f"Linked Service: {service['name']}")

    def test_list_datasets(self, client):
        """Test listing datasets"""
        url = f"{client.base_url}/datasets?api-version=2020-12-01"
        response = requests.get(url, headers=client.get_headers())

        assert response.status_code == 200
        data = response.json()

        if "value" in data:
            for dataset in data["value"]:
                print(f"Dataset: {dataset['name']}")

    def test_list_integration_runtimes(self, client):
        """Test listing integration runtimes"""
        url = f"{client.management_url}/integrationRuntimes?api-version={client.api_version}"
        response = requests.get(url, headers=client.get_headers(use_management=True))

        assert response.status_code == 200
        data = response.json()

        if "value" in data:
            for ir in data["value"]:
                print(f"Integration Runtime: {ir['name']}, Type: {ir['properties']['type']}")


if __name__ == "__main__":
    pytest.main([__file__, "-v", "-s"])
