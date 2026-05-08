# 6.6 Evaluation Environment Configuration

## Introduction

The environment in which AI agent evaluation occurs significantly impacts the reliability, reproducibility, and validity of evaluation results. A well-configured evaluation environment provides the controlled conditions necessary for meaningful testing while remaining representative of production scenarios. This section explores the principles, components, and best practices for configuring evaluation environments that support both rigorous testing and realistic performance assessment.

## Evaluation Environment Fundamentals

### Purpose and Requirements

An evaluation environment must balance several competing needs:

**Isolation and Control**
- Separate from production to prevent user impact
- Controlled variables for reproducibility
- Ability to inject specific conditions
- Safe space for experimentation

**Realism and Representativeness**
- Mirrors production architecture
- Includes realistic data and dependencies
- Reflects actual usage patterns
- Captures system complexity

**Observability and Debugging**
- Comprehensive logging and tracing
- Visibility into agent internals
- Error reproduction capability
- Performance profiling support

**Efficiency and Cost**
- Reasonable execution time
- Manageable infrastructure costs
- Scalable to test suite size
- Reusable across evaluations

### Environment Types

Different evaluation scenarios require different environment configurations:

**Development Environment**
- Local or remote development machines
- Lightweight dependencies
- Fast iteration cycles
- Individual developer access

**CI/CD Environment**
- Automated testing infrastructure
- Containerized execution
- Version-controlled configuration
- Reproducible builds

**Staging Environment**
- Production-like setup
- Pre-deployment validation
- Integration testing
- Performance benchmarking

**Production-Like Environment**
- Full production mirror
- Real-scale data
- Actual dependencies
- Load testing capable

## Core Configuration Components

### Infrastructure Setup

#### Compute Resources

**Development/CI Environments**:
```yaml
resources:
  cpu: 2-4 cores
  memory: 8-16 GB
  storage: 50-100 GB
  gpu: optional, for embedding operations
```

**Staging/Production-Like**:
```yaml
resources:
  cpu: 8-16 cores
  memory: 32-64 GB
  storage: 500 GB - 1 TB
  gpu: recommended for large-scale evaluation
  scaling: auto-scaling based on load
```

#### Containerization

**Docker Configuration Example**:
```dockerfile
FROM python:3.10-slim

# Install dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy agent code and evaluation suite
COPY ./src /app/src
COPY ./evals /app/evals
COPY ./tests /app/tests

# Set environment variables
ENV EVALUATION_MODE=true
ENV LOG_LEVEL=DEBUG

# Run evaluation
CMD ["python", "-m", "evals", "run"]
```

**Benefits**:
- Consistent environment across machines
- Easy replication and distribution
- Isolation from host system
- Version-locked dependencies

### Dependency Management

#### External Services Configuration

**Mocking Strategy**:
- **Full Mock**: Simulate all external APIs with predetermined responses
- **Partial Mock**: Mock unstable services, use real stable ones
- **Record-Replay**: Record production API responses, replay in testing
- **Sandbox Services**: Use test/sandbox versions of production services

**Example Mock Configuration**:
```python
# Mock external API for consistent evaluation
class MockWeatherAPI:
    def __init__(self, responses_file="test_data/weather_responses.json"):
        self.responses = load_responses(responses_file)
    
    def get_weather(self, location):
        # Return predetermined response for testing
        return self.responses.get(location, {"error": "Unknown location"})

# Inject mock in evaluation mode
if os.getenv("EVALUATION_MODE"):
    weather_api = MockWeatherAPI()
else:
    weather_api = RealWeatherAPI()
```

#### Database Configuration

**Test Database Setup**:
- Separate database instance for testing
- Fixtures and seed data for known states
- Transaction rollback for cleanup
- Schema versioning aligned with tests

**Data Management**:
```python
# Evaluation database setup
@pytest.fixture(scope="session")
def test_database():
    db = create_test_database()
    db.load_fixtures("test_fixtures.sql")
    yield db
    db.teardown()

# Test with known data state
def test_agent_with_user_history(test_database):
    user = test_database.get_user("test_user_001")
    agent_response = agent.process(user_query, context=user)
    assert evaluate_response(agent_response)
```

### Model and API Configuration

#### LLM Provider Setup

**Environment Variables**:
```bash
# API Keys
OPENAI_API_KEY=sk-...
ANTHROPIC_API_KEY=sk-ant-...

# Model Selection
PRIMARY_MODEL=gpt-4-turbo
FALLBACK_MODEL=gpt-3.5-turbo

# Evaluation-specific
JUDGE_MODEL=gpt-4
EVALUATOR_TEMPERATURE=0.0
```

**Cost Control**:
```python
# Rate limiting for evaluation
from ratelimit import limits, sleep_and_retry

@sleep_and_retry
@limits(calls=50, period=60)  # 50 calls per minute
def call_llm_judge(input_text, output_text, criteria):
    return judge_model.evaluate(input_text, output_text, criteria)
```

#### Model Versioning

**Lock Model Versions**:
```yaml
# evaluation_config.yml
models:
  agent_model:
    provider: openai
    name: gpt-4-turbo-2024-04-09  # Specific version
    temperature: 0.7
  
  judge_model:
    provider: anthropic
    name: claude-3-opus-20240229  # Specific version
    temperature: 0.0  # Deterministic for consistency
```

**Benefits**:
- Reproducible results across evaluations
- Prevents unexpected behavior from model updates
- Enables controlled model comparison
- Clear audit trail

### Logging and Observability

#### Tracing Configuration

**Instrumentation Setup**:
```python
from opentelemetry import trace
from deepeval.tracing import observe

# Configure tracer
tracer = trace.get_tracer(__name__)

# Instrument agent functions
@observe(type="agent", trace_to="eval_platform")
def customer_service_agent(query):
    with tracer.start_as_current_span("agent_execution"):
        # Agent logic
        response = process_query(query)
        return response

@observe(type="llm")
def call_llm(prompt):
    with tracer.start_as_current_span("llm_call"):
        return llm.generate(prompt)
```

**Trace Export Configuration**:
```yaml
# otel-config.yml
exporters:
  otlp:
    endpoint: "http://eval-platform:4317"
    timeout: 30s
  
  jaeger:
    endpoint: "http://localhost:14250"
  
  console:
    enabled: true  # For local debugging

service:
  pipelines:
    traces:
      receivers: [otlp]
      processors: [batch]
      exporters: [otlp, jaeger, console]
```

#### Structured Logging

**Log Configuration**:
```python
import logging
import json

# JSON structured logging
class JSONFormatter(logging.Formatter):
    def format(self, record):
        log_obj = {
            "timestamp": self.formatTime(record),
            "level": record.levelname,
            "message": record.getMessage(),
            "module": record.module,
            "function": record.funcName,
        }
        if hasattr(record, "eval_context"):
            log_obj["eval_context"] = record.eval_context
        return json.dumps(log_obj)

# Configure logger for evaluation
logging.basicConfig(
    level=logging.DEBUG if EVALUATION_MODE else logging.INFO,
    handlers=[logging.FileHandler("eval_logs.jsonl")],
    formatter=JSONFormatter()
)
```

## Environment Configuration Best Practices

### 1. Separate Development, Testing, and Production

**Configuration Management**:
```
config/
  ├── development.yml
  ├── testing.yml
  ├── staging.yml
  └── production.yml
```

**Environment Selection**:
```python
import os
from config import load_config

ENV = os.getenv("ENVIRONMENT", "development")
config = load_config(f"config/{ENV}.yml")
```

### 2. Use Infrastructure as Code

**Terraform Example**:
```hcl
# evaluation_infrastructure.tf
resource "aws_ecs_task_definition" "eval_runner" {
  family = "agent-evaluation"
  container_definitions = jsonencode([{
    name  = "eval-container"
    image = "agent-eval:latest"
    environment = [
      { name = "EVALUATION_MODE", value = "true" },
      { name = "LOG_LEVEL", value = "DEBUG" }
    ]
  }])
}
```

**Benefits**:
- Version-controlled infrastructure
- Reproducible environments
- Easy environment replication
- Clear documentation

### 3. Implement Secrets Management

**Never Hardcode Secrets**:
```python
# Bad
API_KEY = "sk-abc123..."

# Good
import os
from secretmanager import get_secret

API_KEY = os.getenv("API_KEY") or get_secret("openai_api_key")
```

**Secret Management Solutions**:
- **Development**: `.env` files (excluded from git)
- **CI/CD**: GitHub Secrets, GitLab CI variables
- **Production**: AWS Secrets Manager, HashiCorp Vault, Azure Key Vault

### 4. Ensure Reproducibility

**Deterministic Configuration**:
```python
# Set seeds for reproducibility
import random
import numpy as np

SEED = 42
random.seed(SEED)
np.random.seed(SEED)
# Note: LLM sampling still has inherent randomness unless temp=0
```

**Dependency Locking**:
```
# requirements.txt
deepeval==0.21.28
openai==1.10.0
pytest==7.4.3
# Exact versions for reproducibility
```

### 5. Monitor Environment Health

**Health Checks**:
```python
def check_evaluation_environment():
    checks = {
        "api_connectivity": test_api_connection(),
        "database_reachable": test_database_connection(),
        "model_availability": test_model_access(),
        "trace_export": test_trace_export(),
    }
    
    if not all(checks.values()):
        raise EnvironmentError(f"Environment checks failed: {checks}")
    
    return checks
```

## Specialized Environment Configurations

### CI/CD Environment

**GitHub Actions Example**:
```yaml
# .github/workflows/agent-eval.yml
name: Agent Evaluation

on:
  pull_request:
    branches: [main]

jobs:
  evaluate:
    runs-on: ubuntu-latest
    
    services:
      postgres:
        image: postgres:14
        env:
          POSTGRES_PASSWORD: test
        options: >-
          --health-cmd pg_isready
          --health-interval 10s
    
    steps:
      - uses: actions/checkout@v3
      
      - name: Set up Python
        uses: actions/setup-python@v4
        with:
          python-version: '3.10'
      
      - name: Cache dependencies
        uses: actions/cache@v3
        with:
          path: ~/.cache/pip
          key: ${{ runner.os }}-pip-${{ hashFiles('requirements.txt') }}
      
      - name: Install dependencies
        run: |
          pip install -r requirements.txt
          pip install -r requirements-dev.txt
      
      - name: Run evaluation
        env:
          OPENAI_API_KEY: ${{ secrets.OPENAI_API_KEY }}
          EVALUATION_MODE: true
          DATABASE_URL: postgresql://postgres:test@postgres/testdb
        run: |
          python -m pytest tests/evaluation/ -v --tb=short
      
      - name: Upload results
        if: always()
        uses: actions/upload-artifact@v3
        with:
          name: evaluation-results
          path: eval_results/
```

### Simulation Environments

**Sandbox for Safe Testing**:
```python
class SimulatedEnvironment:
    """Simulated environment for agent testing"""
    
    def __init__(self, config):
        self.config = config
        self.state = {}
        self.action_log = []
    
    def reset(self):
        """Reset to initial state"""
        self.state = self.config["initial_state"]
        self.action_log = []
    
    def execute_action(self, action):
        """Execute action and update state"""
        self.action_log.append(action)
        
        # Simulate action effects
        if action["type"] == "book_flight":
            self.state["bookings"].append(action["params"])
            return {"success": True, "confirmation": "ABC123"}
        
        return {"success": False, "error": "Unknown action"}
    
    def get_state(self):
        """Return current environment state"""
        return self.state.copy()

# Use in evaluation
env = SimulatedEnvironment(config)
for test_case in test_suite:
    env.reset()
    agent_result = agent.run(test_case, environment=env)
    evaluate_result(agent_result, env.get_state())
```

### Production-Like Environments

**Configuration Parity**:
- Use same infrastructure type (e.g., Kubernetes)
- Same service versions
- Similar data volumes
- Equivalent network topology
- Matching security configurations

**Differences from Production**:
- Separate data sources (no real user data)
- Lower scale/replicas
- Enhanced logging/debugging
- Test user accounts only
- Relaxed rate limits for evaluation

## Common Configuration Challenges

### Challenge 1: External Dependency Reliability

**Problem**: Third-party APIs unavailable or rate-limited during evaluation

**Solutions**:
- Mock external services with predictable responses
- Use sandbox/test API endpoints
- Implement retry logic with exponential backoff
- Cache API responses for offline evaluation

### Challenge 2: Non-Determinism in Evaluation

**Problem**: Results vary across identical evaluation runs

**Solutions**:
- Set LLM temperature to 0 where possible
- Lock model versions
- Set random seeds
- Use deterministic test data
- Run multiple iterations and average results

### Challenge 3: Cost Escalation

**Problem**: Evaluation costs become prohibitive

**Solutions**:
- Tier evaluation suites (quick vs. comprehensive)
- Use cheaper models for development evaluation
- Implement caching for repeated evaluations
- Sample-based evaluation for expensive tests
- Optimize test suite size and execution

### Challenge 4: Environment Drift

**Problem**: Evaluation environment diverges from production over time

**Solutions**:
- Infrastructure as code for consistent provisioning
- Regular synchronization with production config
- Automated drift detection
- Periodic full rebuilds from scratch

### Challenge 5: Slow Evaluation Execution

**Problem**: Evaluation takes too long, blocking development

**Solutions**:
- Parallel test execution
- Tiered evaluation (fast smoke tests first)
- Incremental evaluation (only affected tests)
- Optimize test data loading
- Distributed evaluation infrastructure

## Evaluation Environment Checklist

### Pre-Evaluation Setup

- [ ] API keys and credentials configured
- [ ] Model versions locked and specified
- [ ] Test data loaded and accessible
- [ ] External dependencies mocked or sandboxed
- [ ] Logging and tracing enabled
- [ ] Environment health checks passing

### During Evaluation

- [ ] Traces captured correctly
- [ ] Logs written to appropriate destinations
- [ ] Resource utilization within bounds
- [ ] No errors from environment misconfiguration
- [ ] Results stored with proper metadata

### Post-Evaluation

- [ ] Results accessible and backed up
- [ ] Environment cleaned up (temporary data removed)
- [ ] Costs tracked and within budget
- [ ] Artifacts archived appropriately
- [ ] Environment ready for next evaluation

## Conclusion

A well-configured evaluation environment is essential infrastructure for reliable AI agent assessment. By carefully balancing control with realism, isolation with representativeness, and efficiency with thoroughness, teams can create evaluation environments that provide confidence in results while enabling rapid iteration. The key is treating environment configuration as a first-class concern—version-controlled, documented, and maintained with the same rigor as agent code itself.

---

## References

1. Hugging Face. (2025). "Agent Observability and Evaluation." Agents Course. Retrieved from https://huggingface.co/learn/agents-course/en/bonus-unit2/what-is-agent-observability-and-evaluation

2. LangWatch. (2025). "Framework for Evaluating Agents: Simulation Environments." Retrieved from https://langwatch.ai/blog/framework-for-evaluating-agents

3. Arize AI. (2025). "Agent Evaluation: Choosing Which Steps to Evaluate." Retrieved from https://arize.com/ai-agents/agent-evaluation/

4. DeepEval. (2025). "AI Agent Evaluation Guide: Tracing and Observability." Retrieved from https://deepeval.com/guides/guides-ai-agent-evaluation

5. n8n. (2025). "Building your own LLM evaluation framework with n8n." Retrieved from https://blog.n8n.io/llm-evaluation-framework/

6. OpenAI. (2025). "Evals: Setup and Configuration." GitHub Repository. Retrieved from https://github.com/openai/evals
