# dbt-biguqery-llm-enrichment-example

This is an example of using dbt to enrich data in BigQuery with LLM model.

## Getting started

### Prerequisites

- Python 3.11
- GCP project
## Setup

### GCP setup

Create a connection of Cloud Resource type in BigQuery:

> Replace `YOUR_REGION` and `YOUR_PROJECT_ID` with your own values

```bash
bq mk --connection --location=YOUR_REGION --project_id=YOUR_PROJECT_ID --connection_type=CLOUD_RESOURCE cloud_resources_connection
```

### `call_llm_model` Cloud Function setup

Please follow the instructions in [remote_functions/call_llm_model/README.md](remote_functions/call_llm_model/call_llm_model/README.md)

### dbt setup

Create a virtual environment:

```bash
python -m venv venv
source venv/bin/activate
```

Install dependencies:

```bash
pip install -r requirements.txt
```

Setup dbt profile in `~/.dbt/profiles.yml`

Test the connection:

```bash
dbt debug
```

Run dbt models:

> Before running the models, please make sure that you have created a connection of Cloud Resource type in BigQuery and that you have created a Cloud Function `call_llm_model` in your GCP project.

```bash
dbt build
```

## Authors

- [Piotr Pilis](https://github.com/pilis)

Special thanks to [Piotr Chaberski](https://github.com/pchaberski) for reviewing the code and providing valuable feedback.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details
