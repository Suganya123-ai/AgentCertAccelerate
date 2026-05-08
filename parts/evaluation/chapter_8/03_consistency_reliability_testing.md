# Chapter 8.3: Consistency and Reliability Testing

## Overview

Consistency and reliability are critical quality dimensions for production AI agents. Unlike traditional software where the same input reliably produces the same output, AI agents introduce non-determinism that can manifest as inconsistent behavior across runs. This document explores methods for measuring and improving agent consistency while ensuring reliable behavior under varying conditions.

## Understanding Consistency vs. Reliability

### Consistency

**Definition**: The degree to which an agent produces similar outcomes when given the same or similar inputs across multiple runs.

**Key Dimensions**:
1. **Response Consistency**: Similar answers to the same question
2. **Plan Consistency**: Similar reasoning paths for the same task
3. **Tool Selection Consistency**: Choosing the same tools for similar queries
4. **Behavior Consistency**: Maintaining stable patterns across interactions

### Reliability

**Definition**: The agent's ability to perform correctly and predictably across varying conditions, including edge cases and adverse scenarios.

**Key Dimensions**:
1. **Task Completion Reliability**: Consistently achieving goals
2. **Error Handling Reliability**: Gracefully managing failures
3. **Performance Reliability**: Maintaining quality under load
4. **Temporal Reliability**: Stable behavior over time

## The Non-Determinism Challenge

### Sources of Non-Determinism

1. **Model Sampling**:
```python
# Temperature affects consistency
response_1 = model.generate(prompt, temperature=0.0)  # More deterministic
response_2 = model.generate(prompt, temperature=0.7)  # More creative
response_3 = model.generate(prompt, temperature=1.0)  # Highly variable
```

2. **Tool Output Variability**:
- API changes
- Data updates
- Network conditions
- Third-party service variations

3. **Context Variations**:
- Different conversation histories
- Timing of interactions
- User input variations

4. **Model Updates**:
- Provider version changes
- Fine-tuning updates
- Infrastructure changes

### Why This Matters

**Monte Carlo's Experience**:
> "The unique evaluation challenge for AI agents is that they are non-deterministic. In other words, the same input can produce two different outputs. Traditional CI/CD evaluation frameworks with explicitly defined outputs don't work for agentic systems."

## Consistency Measurement Metrics

### 1. Pass^k Reliability Metric

**Definition**: Measures reliability over multiple trial runs (introduced in tau-bench)

**Formula**:
```python
def calculate_pass_k(agent, test_cases, k=8):
    """
    Pass^k: Success rate across k independent runs
    
    Args:
        agent: Agent to test
        test_cases: List of test scenarios
        k: Number of runs per test case
    
    Returns:
        Pass^k score (0 to 1)
    """
    results = []
    
    for test_case in test_cases:
        successes = 0
        
        # Run k times
        for run in range(k):
            outcome = agent.execute(test_case)
            if outcome["success"]:
                successes += 1
        
        # This test passes if successful in ALL k runs
        test_passed = (successes == k)
        results.append(test_passed)
    
    # Overall pass^k rate
    return sum(results) / len(results)
```

**Interpretation**:
- `pass^8 = 0.25` means only 25% of tests passed consistently across 8 runs
- Lower pass^k indicates inconsistent behavior
- Critical for production systems requiring reliability

**Real-World Example** (tau-bench results):
```python
# Even GPT-4o shows inconsistency
{
    "model": "gpt-4o",
    "task_success_rate": 0.45,  # 45% success on individual attempts
    "pass^8_retail": 0.23,       # Only 23% consistent across 8 runs
    "interpretation": "Agent works ~half the time but unreliably"
}
```

### 2. Response Variability

**Semantic Similarity Across Runs**:

```python
from sentence_transformers import SentenceTransformer
from scipy.spatial.distance import cosine

def measure_response_consistency(agent, query, n_runs=5):
    """
    Measure semantic consistency across multiple runs
    """
    model = SentenceTransformer('all-MiniLM-L6-v2')
    responses = []
    
    # Generate multiple responses
    for i in range(n_runs):
        response = agent.process(query)
        responses.append(response)
    
    # Compute embeddings
    embeddings = model.encode(responses)
    
    # Pairwise similarity
    similarities = []
    for i in range(len(embeddings)):
        for j in range(i + 1, len(embeddings)):
            sim = 1 - cosine(embeddings[i], embeddings[j])
            similarities.append(sim)
    
    return {
        "responses": responses,
        "avg_similarity": np.mean(similarities),
        "min_similarity": np.min(similarities),
        "max_similarity": np.max(similarities),
        "consistency_score": np.mean(similarities)  # Higher = more consistent
    }
```

### 3. Plan Adherence Consistency

**DeepEval Approach**:

```python
from deepeval.metrics import PlanAdherenceMetric

plan_adherence = PlanAdherenceMetric()

def test_plan_consistency(agent, query, n_runs=3):
    """
    Check if agent follows its own plans consistently
    """
    adherence_scores = []
    
    for run in range(n_runs):
        result = agent.execute_with_planning(query)
        
        # Evaluate plan adherence
        score = plan_adherence.measure(
            plan=result["plan"],
            execution=result["actions"],
            outcome=result["result"]
        )
        
        adherence_scores.append(score)
    
    return {
        "adherence_scores": adherence_scores,
        "consistent_adherence": np.std(adherence_scores) < 0.2,
        "avg_adherence": np.mean(adherence_scores)
    }
```

### 4. Tool Selection Consistency

```python
def measure_tool_selection_consistency(agent, query, n_runs=5):
    """
    Verify agent uses same tools for same task
    """
    tool_sequences = []
    
    for run in range(n_runs):
        trace = agent.execute_with_trace(query)
        tools_used = [action["tool"] for action in trace["actions"]]
        tool_sequences.append(tools_used)
    
    # Check sequence similarity
    unique_sequences = len(set(map(tuple, tool_sequences)))
    
    return {
        "total_runs": n_runs,
        "unique_sequences": unique_sequences,
        "consistency_ratio": 1 - (unique_sequences - 1) / n_runs,
        "tool_sequences": tool_sequences
    }
```

## Reliability Measurement Methods

### 1. Task Completion Reliability

**DeepEval's TaskCompletionMetric**:

```python
from deepeval.metrics import TaskCompletionMetric

task_completion = TaskCompletionMetric()

def test_completion_reliability(agent, test_set, n_trials=3):
    """
    Test if agent reliably completes tasks
    """
    reliability_scores = []
    
    for test_case in test_set:
        completions = []
        
        for trial in range(n_trials):
            result = agent.execute(test_case)
            
            completed = task_completion.measure(
                task=test_case,
                result=result
            )
            
            completions.append(completed)
        
        # Reliability for this test case
        reliability = sum(completions) / n_trials
        reliability_scores.append(reliability)
    
    return {
        "per_task_reliability": reliability_scores,
        "overall_reliability": np.mean(reliability_scores),
        "reliable_tasks": sum(1 for r in reliability_scores if r >= 0.9)
    }
```

### 2. Error Recovery Reliability

```python
def test_error_recovery(agent, error_scenarios):
    """
    Test agent's ability to recover from errors consistently
    """
    recovery_results = []
    
    for scenario in error_scenarios:
        recoveries = []
        
        # Test recovery multiple times
        for attempt in range(5):
            try:
                # Inject error
                inject_error(scenario["error_type"])
                
                # Attempt recovery
                result = agent.handle_error(scenario["context"])
                
                # Check if recovered
                recovered = verify_recovery(result, scenario["expected"])
                recoveries.append(recovered)
                
            except Exception as e:
                recoveries.append(False)
        
        # Recovery reliability for this scenario
        recovery_rate = sum(recoveries) / len(recoveries)
        recovery_results.append({
            "scenario": scenario["name"],
            "recovery_rate": recovery_rate,
            "reliable": recovery_rate >= 0.8
        })
    
    return recovery_results
```

### 3. Performance Under Load

```python
import asyncio
from concurrent.futures import ThreadPoolExecutor

async def test_load_reliability(agent, queries, concurrent_users=[1, 10, 50, 100]):
    """
    Test reliability under varying load
    """
    results = {}
    
    for concurrency in concurrent_users:
        # Run queries concurrently
        tasks = []
        for query in queries[:concurrency]:
            task = asyncio.create_task(agent.process_async(query))
            tasks.append(task)
        
        # Gather results
        responses = await asyncio.gather(*tasks, return_exceptions=True)
        
        # Analyze reliability
        successful = sum(1 for r in responses if not isinstance(r, Exception))
        errors = sum(1 for r in responses if isinstance(r, Exception))
        
        results[concurrency] = {
            "total": len(responses),
            "successful": successful,
            "errors": errors,
            "reliability": successful / len(responses),
            "avg_latency": calculate_avg_latency(responses)
        }
    
    return results
```

## Best Practices for Improving Consistency

### 1. Temperature Control

**Optimize for consistency**:

```python
# Configuration for consistent behavior
CONSISTENCY_CONFIG = {
    "temperature": 0.0,          # Most deterministic
    "top_p": 1.0,                # No nucleus sampling
    "frequency_penalty": 0.0,    # No repetition penalty
    "presence_penalty": 0.0,     # No presence penalty
    "seed": 42                   # Fixed seed (if supported)
}

def consistent_agent_call(prompt, model="gpt-4"):
    response = openai.ChatCompletion.create(
        model=model,
        messages=[{"role": "user", "content": prompt}],
        **CONSISTENCY_CONFIG
    )
    return response
```

**Trade-offs**:
- Lower temperature = More consistent but less creative
- Higher temperature = More varied but potentially better quality
- Choose based on use case requirements

### 2. Structured Output Formats

**Enforce consistency through schema**:

```python
from pydantic import BaseModel, Field

class AgentResponse(BaseModel):
    """Structured response format"""
    answer: str = Field(description="Main response")
    confidence: float = Field(ge=0.0, le=1.0)
    sources: List[str] = Field(default_factory=list)
    tool_calls: List[Dict] = Field(default_factory=list)
    
def get_structured_response(query):
    response = agent.generate(
        query=query,
        response_format={"type": "json_object"},
        response_schema=AgentResponse.schema()
    )
    
    # Parse and validate
    parsed = AgentResponse.parse_raw(response)
    return parsed
```

### 3. Deterministic Tool Execution

```python
class DeterministicToolExecutor:
    """Ensure consistent tool execution"""
    
    def __init__(self):
        self.cache = {}
        self.retry_config = {
            "max_attempts": 3,
            "backoff_factor": 2
        }
    
    def execute_tool(self, tool_name, args, use_cache=True):
        """
        Execute tool with caching and retry logic
        """
        # Generate cache key
        cache_key = self._get_cache_key(tool_name, args)
        
        # Check cache for consistency
        if use_cache and cache_key in self.cache:
            return self.cache[cache_key]
        
        # Execute with retry
        result = self._execute_with_retry(tool_name, args)
        
        # Cache result
        if use_cache:
            self.cache[cache_key] = result
        
        return result
    
    def _execute_with_retry(self, tool_name, args):
        """Retry logic for reliability"""
        for attempt in range(self.retry_config["max_attempts"]):
            try:
                result = self._call_tool(tool_name, args)
                return result
            except Exception as e:
                if attempt == self.retry_config["max_attempts"] - 1:
                    raise
                wait_time = self.retry_config["backoff_factor"] ** attempt
                time.sleep(wait_time)
```

### 4. Soft Failures and Thresholds

**Monte Carlo's Approach**:

```python
class SoftFailureEvaluator:
    """
    Implement soft failures for non-deterministic systems
    """
    
    THRESHOLDS = {
        "hard_failure": 0.5,    # Below this = hard fail
        "soft_failure": 0.8,    # Between = soft fail
        "pass": 0.8              # Above this = pass
    }
    
    def __init__(self, max_soft_failures=2, soft_failure_threshold=0.33):
        self.max_soft_failures = max_soft_failures
        self.soft_failure_threshold = soft_failure_threshold
    
    def evaluate_run(self, test_results):
        """
        Evaluate with soft failure tolerance
        """
        hard_failures = 0
        soft_failures = 0
        passes = 0
        
        for result in test_results:
            score = result["score"]
            
            if score < self.THRESHOLDS["hard_failure"]:
                hard_failures += 1
            elif score < self.THRESHOLDS["soft_failure"]:
                soft_failures += 1
            else:
                passes += 1
        
        # Check if within acceptable limits
        total = len(test_results)
        soft_failure_rate = soft_failures / total
        
        overall_pass = (
            hard_failures == 0 and
            soft_failures <= self.max_soft_failures and
            soft_failure_rate < self.soft_failure_threshold
        )
        
        return {
            "overall_pass": overall_pass,
            "hard_failures": hard_failures,
            "soft_failures": soft_failures,
            "passes": passes,
            "soft_failure_rate": soft_failure_rate
        }
```

### 5. Automatic Retry with Verification

```python
async def reliable_execution_with_retry(agent, query, max_retries=3):
    """
    Retry execution with consistency verification
    """
    responses = []
    
    for attempt in range(max_retries):
        response = await agent.process_async(query)
        responses.append(response)
        
        # Check consistency with previous responses
        if len(responses) >= 2:
            consistency = check_consistency(responses[-2], responses[-1])
            
            if consistency["score"] >= 0.8:
                # Responses are consistent, return
                return response
        
        # If final attempt, return best response
        if attempt == max_retries - 1:
            # Choose most common response
            return select_consensus_response(responses)
    
    return responses[-1]
```

## Testing Strategies

### 1. Repeated Execution Tests

```python
def test_repeated_execution(agent, test_suite, n_repeats=5):
    """
    Run entire test suite multiple times
    """
    all_results = []
    
    for repeat in range(n_repeats):
        repeat_results = []
        
        for test_case in test_suite:
            result = agent.execute(test_case)
            repeat_results.append({
                "test_id": test_case["id"],
                "result": result,
                "success": result["success"]
            })
        
        all_results.append(repeat_results)
    
    # Analyze consistency across repeats
    consistency_report = analyze_consistency(all_results)
    
    return {
        "raw_results": all_results,
        "consistency_report": consistency_report,
        "unreliable_tests": identify_unreliable_tests(all_results)
    }
```

### 2. Stress Testing

```python
def stress_test_reliability(agent, duration_minutes=30):
    """
    Continuous stress testing
    """
    start_time = time.time()
    end_time = start_time + (duration_minutes * 60)
    
    results = {
        "total_requests": 0,
        "successes": 0,
        "failures": 0,
        "errors": [],
        "performance_degradation": []
    }
    
    baseline_latency = None
    
    while time.time() < end_time:
        try:
            start = time.time()
            response = agent.process(generate_random_query())
            latency = time.time() - start
            
            results["total_requests"] += 1
            
            if baseline_latency is None:
                baseline_latency = latency
            
            # Check for performance degradation
            if latency > baseline_latency * 2:
                results["performance_degradation"].append({
                    "timestamp": time.time(),
                    "latency": latency,
                    "baseline": baseline_latency
                })
            
            if response["success"]:
                results["successes"] += 1
            else:
                results["failures"] += 1
                results["errors"].append(response["error"])
        
        except Exception as e:
            results["failures"] += 1
            results["errors"].append(str(e))
    
    results["reliability_score"] = results["successes"] / results["total_requests"]
    
    return results
```

### 3. Time-Based Consistency Testing

```python
def test_temporal_consistency(agent, test_cases, test_intervals=[0, 1, 24, 168]):
    """
    Test consistency over time (hours)
    
    Args:
        test_intervals: Hours between tests [immediate, 1hr, 1day, 1week]
    """
    temporal_results = {}
    
    for test_case in test_cases:
        test_results = []
        
        for interval_hours in test_intervals:
            # Wait for interval (in real testing)
            # time.sleep(interval_hours * 3600)
            
            # Simulate with different timestamps for demo
            result = agent.execute(test_case)
            test_results.append({
                "interval": interval_hours,
                "result": result,
                "timestamp": time.time()
            })
        
        # Analyze temporal consistency
        temporal_results[test_case["id"]] = {
            "results": test_results,
            "consistent_over_time": check_temporal_consistency(test_results)
        }
    
    return temporal_results
```

## Production Monitoring

### 1. Real-Time Consistency Tracking

```python
class ConsistencyMonitor:
    """Monitor consistency in production"""
    
    def __init__(self, window_size=100):
        self.recent_responses = deque(maxlen=window_size)
        self.query_patterns = {}
    
    def track_response(self, query, response):
        """Track responses for similar queries"""
        # Normalize query
        query_pattern = self._normalize_query(query)
        
        if query_pattern not in self.query_patterns:
            self.query_patterns[query_pattern] = []
        
        self.query_patterns[query_pattern].append({
            "query": query,
            "response": response,
            "timestamp": time.time()
        })
        
        # Calculate consistency for this pattern
        if len(self.query_patterns[query_pattern]) >= 5:
            consistency = self._calculate_pattern_consistency(query_pattern)
            
            if consistency < 0.7:
                self._alert_inconsistency(query_pattern, consistency)
    
    def get_consistency_metrics(self):
        """Get current consistency metrics"""
        metrics = {}
        
        for pattern, responses in self.query_patterns.items():
            if len(responses) >= 2:
                consistency = self._calculate_pattern_consistency(pattern)
                metrics[pattern] = {
                    "sample_count": len(responses),
                    "consistency_score": consistency
                }
        
        return metrics
```

### 2. Automated Alerts

```python
def setup_reliability_alerts(agent_id, thresholds):
    """
    Configure alerts for reliability issues
    """
    alert_config = {
        "pass_k_threshold": 0.8,          # Alert if pass^8 < 0.8
        "consistency_threshold": 0.7,      # Alert if consistency < 0.7
        "error_rate_threshold": 0.05,      # Alert if error rate > 5%
        "latency_multiplier": 2.0          # Alert if latency > 2x baseline
    }
    
    @observe(metric_collection=f"reliability-{agent_id}")
    async def monitored_agent_call(query):
        result = await agent.process(query)
        
        # Check reliability metrics
        if result["consistency"] < alert_config["consistency_threshold"]:
            send_alert("Consistency degradation detected", result)
        
        if result["error_rate"] > alert_config["error_rate_threshold"]:
            send_alert("High error rate detected", result)
        
        return result
```

## Research Citations

Key frameworks and findings:
- tau-bench: Introduction of pass^k reliability metric
- Monte Carlo: Soft failure approach for non-deterministic systems
- DeepEval: PlanAdherenceMetric and TaskCompletionMetric
- Azure AI Foundry: Reproducible evaluation workflows
- W&B Weave: Consistency tracking and visualization

## Conclusion

Consistency and reliability in AI agents require:

1. **Acceptance of Non-Determinism**: Traditional CI/CD expectations don't apply
2. **Multi-Run Testing**: Use metrics like pass^k to measure reliability
3. **Soft Failure Tolerances**: Build flexibility into evaluation
4. **Continuous Monitoring**: Track consistency in production
5. **Error Recovery**: Test and improve failure handling

Key insights:
- Even state-of-the-art models show significant inconsistency
- pass^k scores often substantially lower than single-run success rates
- Soft failures and retry mechanisms essential for production reliability
- Consistency requirements vary by use case (deterministic tasks vs. creative tasks)

By implementing comprehensive consistency and reliability testing, teams can:
- Identify unreliable behaviors before production
- Set realistic expectations for agent performance
- Build appropriate retry and fallback mechanisms
- Monitor and maintain quality over time
