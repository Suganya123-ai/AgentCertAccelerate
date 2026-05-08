# Chapter 8.2: Hallucination Detection and Measurement

## Overview

Hallucinations represent one of the most critical failure modes in AI agents - generating plausible-sounding but factually incorrect or unsupported information. Unlike simple errors, hallucinations are often confident and coherent, making them particularly dangerous in production systems. This document explores methods for detecting, measuring, and mitigating hallucinations in AI agent workflows.

## Understanding Hallucinations

### Types of Hallucinations

1. **Factual Hallucinations**
   - False or fabricated information presented as fact
   - Example: "The Eiffel Tower was built in 1923" (actual: 1889)

2. **Context Hallucinations**
   - Claims not supported by provided context/sources
   - Example: Citing information not in retrieved documents

3. **Capability Hallucinations**
   - Claiming abilities the agent doesn't have
   - Example: "I can access your bank account" when it cannot

4. **Temporal Hallucinations**
   - Incorrect time-sensitive information
   - Example: Providing outdated flight prices as current

5. **Computational Hallucinations**
   - Incorrect calculations or data transformations
   - Example: Wrong mathematical results from tool outputs

### Why Hallucinations Matter

**Business Impact**:
- Loss of user trust
- Potential legal liability
- Financial consequences (wrong bookings, orders)
- Brand damage
- Regulatory compliance issues

**Technical Challenges**:
- Difficult to detect automatically
- Often sound plausible and coherent
- May pass simple accuracy checks
- Require deep contextual understanding

## Detection Methods

### 1. Groundedness Evaluation

**Core Principle**: Verify all claims are supported by evidence

**Azure AI Foundry Implementation**:

```python
from azure.ai.evaluation import GroundednessEvaluator

groundedness_eval = GroundednessEvaluator(model_config)

result = groundedness_eval(
    query=user_query,
    response=agent_response,
    tool_definitions=available_tools
)

# Output includes:
# - groundedness_score: 0-1 or 1-5 Likert
# - groundedness_result: "pass" or "fail"
# - groundedness_reason: Explanation
```

**Two-Part Evaluation**:

1. **When context is present**:
```python
# Check if response is grounded in tool outputs
{
    "context": tool_outputs,
    "response": agent_response,
    "evaluation": "All claims must be supported"
}
```

2. **When context is missing**:
```python
# Agent should decline to answer
expected_behaviors = [
    "I don't have that information",
    "I cannot access that data",
    "Could you provide more details?"
]
```

### 2. Multi-Source Verification

**Cross-Reference Strategy**:

```python
def verify_claim(claim, sources):
    """
    Verify a claim against multiple sources
    """
    evidence = []
    
    for source in sources:
        # Extract relevant information
        relevant_content = retrieve_relevant(source, claim)
        evidence.append({
            "source": source,
            "content": relevant_content,
            "supports_claim": check_support(claim, relevant_content)
        })
    
    # Require agreement from multiple sources
    support_count = sum(1 for e in evidence if e["supports_claim"])
    confidence = support_count / len(sources)
    
    return {
        "claim": claim,
        "verified": confidence >= 0.6,
        "confidence": confidence,
        "evidence": evidence
    }
```

### 3. Self-Consistency Checks

**Principle**: Ask the same question multiple ways and check for consistency

```python
from deepeval.metrics import GEval

async def self_consistency_check(query, agent, n_samples=3):
    """
    Run agent multiple times and check consistency
    """
    responses = []
    
    for i in range(n_samples):
        response = await agent.process(query)
        responses.append(response)
    
    # Check if all responses agree on key facts
    consistency_score = calculate_agreement(responses)
    
    return {
        "responses": responses,
        "consistency_score": consistency_score,
        "likely_hallucination": consistency_score < 0.7
    }
```

### 4. LLM-as-a-Judge for Hallucination Detection

**Specialized Prompting**:

```python
HALLUCINATION_DETECTION_PROMPT = """
You are evaluating an AI agent's response for potential hallucinations.

Context/Sources:
{context}

Agent Response:
{response}

Evaluate the response for:
1. Factual claims not supported by the context
2. Made-up information presented as fact
3. Overstated capabilities
4. Conflicting or contradictory statements

Respond in JSON format:
{
    "hallucination_detected": boolean,
    "hallucination_type": "factual" | "context" | "capability" | "none",
    "severity": "low" | "medium" | "high",
    "specific_claims": [list of unsupported claims],
    "explanation": "detailed reasoning"
}
"""

def detect_hallucinations(response, context, judge_model):
    prompt = HALLUCINATION_DETECTION_PROMPT.format(
        context=context,
        response=response
    )
    
    result = judge_model.complete(prompt, response_format="json")
    return json.loads(result)
```

### 5. Retrieval Verification

**For RAG-based agents**:

```python
def verify_rag_response(query, response, retrieved_docs):
    """
    Verify RAG response against retrieved documents
    """
    # Extract claims from response
    claims = extract_claims(response)
    
    verification_results = []
    
    for claim in claims:
        # Find supporting evidence in retrieved docs
        evidence = find_evidence(claim, retrieved_docs)
        
        if not evidence:
            verification_results.append({
                "claim": claim,
                "status": "unsupported",
                "severity": "high"
            })
        elif evidence["confidence"] < 0.5:
            verification_results.append({
                "claim": claim,
                "status": "weak_support",
                "severity": "medium",
                "evidence": evidence
            })
        else:
            verification_results.append({
                "claim": claim,
                "status": "verified",
                "evidence": evidence
            })
    
    hallucination_rate = len([r for r in verification_results 
                              if r["status"] == "unsupported"]) / len(claims)
    
    return {
        "hallucination_rate": hallucination_rate,
        "claim_details": verification_results
    }
```

## Measurement Metrics

### 1. Hallucination Rate

**Definition**: Percentage of responses containing hallucinations

```python
def calculate_hallucination_rate(evaluations):
    total = len(evaluations)
    hallucinated = sum(1 for e in evaluations 
                       if e["hallucination_detected"])
    
    return {
        "hallucination_rate": hallucinated / total,
        "total_evaluated": total,
        "hallucinated_count": hallucinated
    }
```

**Thresholds** (domain-dependent):
- Critical systems (healthcare, finance): < 0.5%
- General assistants: < 5%
- Experimental/beta: < 15%

### 2. Groundedness Score

**Azure AI Foundry Approach**:

```python
# Average groundedness across test set
groundedness_scores = []

for test_case in dataset:
    result = groundedness_eval(
        query=test_case["query"],
        response=test_case["agent_response"],
        tool_definitions=tools
    )
    groundedness_scores.append(result["groundedness"])

avg_groundedness = sum(groundedness_scores) / len(groundedness_scores)

print(f"Average Groundedness: {avg_groundedness:.2f}")
print(f"Pass Rate (threshold=3): {sum(1 for s in groundedness_scores if s >= 3) / len(groundedness_scores):.2%}")
```

### 3. Claim-Level Verification

**Granular Analysis**:

```python
def claim_level_metrics(response, context):
    claims = extract_claims(response)
    
    verified = 0
    unsupported = 0
    contradicted = 0
    
    for claim in claims:
        verification = verify_claim_against_context(claim, context)
        
        if verification == "supported":
            verified += 1
        elif verification == "contradicted":
            contradicted += 1
        else:
            unsupported += 1
    
    return {
        "total_claims": len(claims),
        "verified_claims": verified,
        "unsupported_claims": unsupported,
        "contradicted_claims": contradicted,
        "verification_rate": verified / len(claims) if claims else 0,
        "hallucination_rate": (unsupported + contradicted) / len(claims) if claims else 0
    }
```

### 4. Severity-Weighted Scoring

**Not all hallucinations are equally harmful**:

```python
SEVERITY_WEIGHTS = {
    "low": 1.0,      # Minor factual error
    "medium": 3.0,   # Significant misinformation
    "high": 10.0,    # Dangerous or critical error
    "critical": 50.0 # Could cause serious harm
}

def weighted_hallucination_score(hallucinations):
    if not hallucinations:
        return 0.0
    
    total_weight = sum(SEVERITY_WEIGHTS[h["severity"]] 
                      for h in hallucinations)
    
    # Normalize by maximum possible weight
    max_weight = len(hallucinations) * SEVERITY_WEIGHTS["critical"]
    
    return total_weight / max_weight
```

## Best Practices

### 1. Multi-Layer Defense

**Implement defense-in-depth**:

```python
class HallucinationDefense:
    def __init__(self):
        self.pre_generation_checks = []
        self.post_generation_checks = []
        self.monitoring_checks = []
    
    def validate_response(self, query, response, context):
        # Layer 1: Fast deterministic checks
        if self.check_prohibited_patterns(response):
            return {"blocked": True, "reason": "Prohibited pattern"}
        
        # Layer 2: Context groundedness
        groundedness = self.check_groundedness(response, context)
        if groundedness["score"] < 0.6:
            return {"blocked": True, "reason": "Insufficient grounding"}
        
        # Layer 3: LLM-as-judge (expensive but thorough)
        hallucination_check = self.detect_hallucinations(response, context)
        if hallucination_check["detected"]:
            return {"blocked": True, "reason": hallucination_check["explanation"]}
        
        # Layer 4: Log for monitoring
        self.log_for_monitoring(query, response, context)
        
        return {"blocked": False, "response": response}
```

### 2. Confidence Calibration

**Teach agents to express uncertainty**:

```python
CALIBRATED_PROMPT_ADDITION = """
When responding:
- Use phrases like "According to the provided context..." for supported claims
- Say "I don't have information about..." when context is insufficient
- Express uncertainty with "likely", "possibly", "based on available data" when appropriate
- Never invent facts - admit when you don't know
"""

# Measure calibration
def measure_confidence_calibration(predictions, reality):
    """
    Check if agent's confidence matches actual accuracy
    """
    buckets = {
        "high_confidence": [],
        "medium_confidence": [],
        "low_confidence": []
    }
    
    for pred, actual in zip(predictions, reality):
        confidence = pred["confidence_level"]
        correct = pred["response"] == actual
        buckets[confidence].append(correct)
    
    calibration = {}
    for level, results in buckets.items():
        if results:
            accuracy = sum(results) / len(results)
            calibration[level] = accuracy
    
    return calibration
```

### 3. Source Attribution

**Always link claims to sources**:

```python
def response_with_citations(query, agent):
    response = agent.process(query)
    
    # Extract claims and find supporting sources
    claims = extract_claims(response["text"])
    citations = []
    
    for claim in claims:
        sources = find_supporting_sources(claim, response["context"])
        citations.append({
            "claim": claim,
            "sources": sources,
            "confidence": calculate_source_confidence(sources)
        })
    
    # Annotate response with citations
    annotated_response = annotate_with_citations(
        response["text"], 
        citations
    )
    
    return {
        "response": annotated_response,
        "citations": citations,
        "unsupported_claims": [c for c in citations if not c["sources"]]
    }
```

### 4. Continuous Monitoring

**Production hallucination tracking**:

```python
@observe(metric_collection="hallucination-monitoring")
def production_agent(user_input, context):
    response = agent.generate_response(user_input, context)
    
    # Async hallucination check (non-blocking)
    asyncio.create_task(
        check_hallucination_async(response, context)
    )
    
    return response

async def check_hallucination_async(response, context):
    # Run thorough hallucination checks
    result = await hallucination_detector.evaluate(response, context)
    
    # Log to monitoring system
    if result["hallucination_detected"]:
        await alert_system.send_alert(
            severity=result["severity"],
            details=result
        )
```

### 5. User Feedback Integration

**Learn from user reports**:

```python
def collect_hallucination_feedback(response_id, user_feedback):
    """
    When users report incorrect information
    """
    if user_feedback["type"] == "incorrect_information":
        # Retrieve original response and context
        original = get_response_by_id(response_id)
        
        # Add to hallucination training set
        hallucination_dataset.add({
            "query": original["query"],
            "response": original["response"],
            "context": original["context"],
            "user_report": user_feedback["details"],
            "verified_as_hallucination": True
        })
        
        # Trigger model retraining if threshold exceeded
        if len(hallucination_dataset) % 100 == 0:
            trigger_model_update()
```

## Mitigation Strategies

### 1. Prompt Engineering

**Anti-hallucination prompts**:

```python
ANTI_HALLUCINATION_SYSTEM_PROMPT = """
You are a helpful AI assistant. Follow these strict rules:

1. ONLY use information from the provided context
2. If information is not in the context, explicitly state "I don't have information about that"
3. Never guess or make up information
4. If you're uncertain, express your uncertainty
5. Cite specific parts of the context when making claims
6. Distinguish between facts in the context and your reasoning

Remember: It's better to admit you don't know than to provide incorrect information.
"""
```

### 2. Context Expansion

**Provide richer context to reduce hallucinations**:

```python
def expand_context(query, initial_context, max_expansions=3):
    """
    Iteratively expand context to reduce hallucination risk
    """
    context = initial_context
    
    for i in range(max_expansions):
        # Check if current context is sufficient
        sufficiency = check_context_sufficiency(query, context)
        
        if sufficiency["sufficient"]:
            break
        
        # Retrieve additional context for gaps
        additional = retrieve_context(
            query, 
            focus_areas=sufficiency["gaps"]
        )
        
        context = merge_contexts(context, additional)
    
    return context
```

### 3. Output Constraints

**Structured outputs reduce hallucination risk**:

```python
def constrained_generation(query, schema):
    """
    Use structured output format to constrain generation
    """
    response = agent.generate(
        query=query,
        response_format={
            "type": "json_schema",
            "json_schema": schema
        }
    )
    
    # Validate against schema
    validation = validate_json_schema(response, schema)
    
    if not validation["valid"]:
        # Regenerate with error feedback
        return constrained_generation(
            query + f"\n\nPrevious attempt failed: {validation['errors']}",
            schema
        )
    
    return response
```

### 4. Retrieval Quality Improvement

**Better retrieval = fewer hallucinations**:

```python
def improved_retrieval(query, knowledge_base):
    """
    Multi-stage retrieval with quality checks
    """
    # Stage 1: Initial retrieval
    candidates = knowledge_base.retrieve(query, top_k=20)
    
    # Stage 2: Rerank by relevance
    reranked = rerank_by_relevance(query, candidates, top_k=10)
    
    # Stage 3: Filter by quality
    quality_filtered = [
        doc for doc in reranked
        if doc["quality_score"] > 0.7
    ]
    
    # Stage 4: Verify freshness
    fresh_docs = [
        doc for doc in quality_filtered
        if not is_outdated(doc, max_age_days=30)
    ]
    
    return fresh_docs
```

## Testing Strategies

### 1. Adversarial Test Cases

**Design tests to provoke hallucinations**:

```python
ADVERSARIAL_TEST_CASES = [
    {
        "query": "What did the CEO say about Q4 earnings?",
        "context": "Q3 earnings report (no Q4 data)",
        "expected": "decline to answer or state no Q4 data available"
    },
    {
        "query": "When was the product launched?",
        "context": "Product announcement only, no launch date",
        "expected": "state launch date not available in context"
    },
    {
        "query": "What's the price of item X?",
        "context": "Description of item X, but no pricing",
        "expected": "acknowledge missing pricing information"
    }
]

def run_adversarial_tests(agent, test_cases):
    results = []
    
    for test in test_cases:
        response = agent.process(test["query"], test["context"])
        
        # Check if agent appropriately declined
        declined = check_appropriate_decline(response, test["expected"])
        
        results.append({
            "test": test,
            "response": response,
            "passed": declined,
            "hallucinated": not declined
        })
    
    return results
```

### 2. Known-False Information Tests

```python
def test_resistance_to_false_context():
    """
    Inject known-false information and see if agent propagates it
    """
    false_context = [
        "The Eiffel Tower was built in 2005",  # False
        "Water boils at 50°C",  # False
        "Python was invented in 2020"  # False
    ]
    
    queries = [
        "When was the Eiffel Tower built?",
        "At what temperature does water boil?",
        "When was Python created?"
    ]
    
    for context, query in zip(false_context, queries):
        response = agent.process(query, context=[context])
        
        # Agent should either:
        # 1. Question the context
        # 2. Express uncertainty
        # 3. Refuse to answer
        # NOT: Confidently repeat false information
        
        assert not repeats_false_info(response, context), \
            f"Agent propagated false information: {response}"
```

## Research Citations

Key frameworks and papers:
- Azure AI Foundry: GroundednessEvaluator and GroundednessProEvaluator
- Monte Carlo: Groundedness evaluation for production agents
- DeepEval: Hallucination detection in agent workflows
- SuperAnnotate: Human-in-the-loop hallucination verification
- Leanware: Hallucination rate metrics in agent evaluation

## Conclusion

Hallucination detection and measurement require:

1. **Multi-method approach**: Combine automated checks, LLM judges, and human review
2. **Context awareness**: Verify all claims against available context
3. **Severity classification**: Not all hallucinations are equally harmful
4. **Continuous monitoring**: Track hallucination rates in production
5. **User feedback loops**: Learn from real-world hallucination reports

The goal is not to achieve zero hallucinations (often impossible with LLMs) but to:
- Detect them reliably
- Measure their frequency and severity
- Implement appropriate guardrails
- Continuously improve through monitoring and iteration

By treating hallucination detection as a core component of agent evaluation rather than an afterthought, teams can build more trustworthy and reliable AI systems.
