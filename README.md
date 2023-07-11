# dbt-biguqery-llm-enrichment-example

## Setup

Create a connection of Cloud Resource type in BigQuery:

> Replace `YOUR_REGION` and `YOUR_PROJECT_ID` with your own values

```bash
bq mk --connection --location=YOUR_REGION --project_id=YOUR_PROJECT_ID --connection_type=CLOUD_RESOURCE cloud_resources_connection
```

Try running the following commands:
- dbt run
- dbt test


### Resources:
- Learn more about dbt [in the docs](https://docs.getdbt.com/docs/introduction)
- Check out [Discourse](https://discourse.getdbt.com/) for commonly asked questions and answers
- Join the [chat](https://community.getdbt.com/) on Slack for live discussions and support
- Find [dbt events](https://events.getdbt.com) near you
- Check out [the blog](https://blog.getdbt.com/) for the latest news on dbt's development and best practices
