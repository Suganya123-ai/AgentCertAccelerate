# 6.3 Deterministic vs. Non-Deterministic Evaluation Approaches

## Introduction

One of the fundamental challenges in AI agent evaluation is that these systems are inherently non-deterministic. Unlike traditional software where the same input consistently produces the same output, AI agents powered by large language models can generate different responses for identical inputs. This non-determinism extends to the evaluation process itself, creating unique challenges that require novel approaches. This section explores the spectrum from deterministic to non-deterministic evaluation, practical strategies for testing unpredictable systems, and how to build reliable evaluation frameworks despite inherent variability.

## Understanding Determinism in Software Testing

### Traditional Software Testing Paradigm

Classical software testing operates on deterministic principles:

**Fixed Input-Output Relationships**
- Given input X, function always returns output Y
- Test assertions check for exact matches
- Failures are binary: pass or fail
- Reproducible results across test runs

**Benefits of Deterministic Testing**
- Clear, unambiguous results
- Easy to debug failures
- Reliable regression detection
- Simple to automate
- Low cost and fast execution

**CI/CD Integration**
- Tests run on every code change
- Hard failures block merges
- Clear pass/fail gates
- No room for interpretation

### The Non-Deterministic Reality of AI Agents

AI agents introduce fundamental non-determinism at multiple levels:

**Model-Level Variability**
- Temperature settings allow controlled randomness
- Different sampling methods (top-k, nucleus sampling)
- Model updates and version changes
- Context window limitations affecting behavior

**System-Level Non-Determinism**
- Tool call sequencing variations
- Reasoning path differences for same goal
- Variable response lengths and formats
- Emergent behaviors from complex interactions

**Environmental Factors**
- External API changes and availability
- Real-world data drift
- Timing-dependent interactions
- Context accumulated from previous interactions

## The Challenge: Non-Deterministic Systems Need Non-Deterministic Tests

### Why Traditional Testing Fails

Simply applying traditional CI/CD testing to AI agents doesn't work:

**Problem 1: Different Paths, Same Destination**
- An agent might book a flight successfully via 3 steps or 7 steps
- Both achieve the goal, but exact outputs differ
- Traditional exact-match assertions would fail

**Problem 2: Evaluator Hallucinations**
- Even LLM-as-judge evaluators are non-deterministic
- Testing for hallucinations with systems that can hallucinate
- Evaluation reliability becomes uncertain

**Problem 3: Spurious Failures**
- About 1 in 10 tests can produce false negatives
- Output is correct, but evaluation scores it as wrong
- Hard failures would block legitimate improvements

## Deterministic Evaluation Approaches

Despite the challenges, deterministic methods remain valuable for specific aspects of evaluation:

### When Deterministic Testing Works

**Format and Structure Validation**
- JSON schema compliance
- Required field presence
- Data type verification
- API response format checking

**Tool Usage Verification**
- Correct tool was called (yes/no)
- Expected parameters provided
- No forbidden tools invoked
- Tool call sequence follows constraints

**Guardrail Testing**
- PII detection and masking
- Toxicity screening thresholds
- Safety boundary enforcement
- Compliance rule adherence

**Efficiency Metrics**
- Token count measurements
- Execution time tracking
- API call counting
- Resource utilization monitoring

### Implementing Deterministic Evaluations

**Code-Based Evaluators**
```python
# Example: Deterministic format check
def evaluate_json_format(output):
    try:
        data = json.loads(output)
        required_fields = ['confirmation', 'price', 'date']
        return all(field in data for field in required_fields)
    except:
        return False
```

**String Similarity Metrics**
- Exact match for specific phrases
- Regular expression matching
- Keyword presence checks
- Character-level distance (Levenshtein)

**Categorical Matching**
- Classification label comparison
- Sentiment matching (positive/negative/neutral)
- Named entity extraction verification
- Intent classification accuracy

### Limitations of Purely Deterministic Approaches

**Insufficient Coverage**
- Cannot assess semantic meaning
- Miss contextually appropriate variations
- Fail to evaluate reasoning quality
- Don't capture user satisfaction

**False Negatives**
- Reject valid alternative formulations
- Penalize acceptable synonyms
- Ignore stylistic variations
- Over-constrain creative solutions

**Example Failure**: Cosine similarity between embeddings seemed promising for semantic distance measurement, but teams found "too many cases where the wording was similar but the meaning was different"—showing that deterministic approximations of semantic understanding are insufficient.

## Non-Deterministic Evaluation Approaches

### LLM-as-Judge Methodology

Using capable LLMs to evaluate agent outputs addresses the semantic understanding gap:

**Core Concept**
- Highly capable model (e.g., GPT-4, Claude 3.5 Sonnet) acts as evaluator
- Judges quality based on criteria provided in prompts
- Returns structured scores and explanations
- Handles open-ended, subjective assessments

**When to Use LLM-as-Judge**
- Open-ended tasks (creative writing, summarization)
- Semantic similarity assessment
- Qualitative criteria (helpfulness, relevance, coherence)
- Complex reasoning evaluation
- When no ground truth exists

**Scoring Approaches**
- Numeric scales (1-5, 0-1 ranges)
- Binary classifications (helpful/not helpful)
- Multi-dimensional rubrics
- Pairwise comparisons (which output is better?)

### Semantic Distance Evaluation

Moving beyond exact matches to evaluate meaning:

**Approach**
- Compare semantic similarity between expected and actual outputs
- Judge whether meaning is preserved despite different wording
- Assess if substantial information is missing or incorrect
- Evaluate contextual appropriateness

**Implementation**
- LLM-based semantic comparison
- Embedding-based similarity (with caution)
- Natural language inference models
- Human-validated rubrics

### Groundedness and Context Adherence

Evaluating whether agents use provided context correctly:

**Two-Part Assessment**

1. **Context Present**: When relevant information is available:
   - Answer must be grounded in provided context
   - Claims must be supported by evidence
   - No unsupported assertions
   - Accurate use of retrieved information

2. **Context Missing**: When information is unavailable:
   - Agent should acknowledge limitations
   - Refuse to answer out-of-scope questions
   - Not invent facts or capabilities
   - Follow guardrail constraints

**Hallucination Detection**
- Fact-checking against knowledge base
- Citation verification
- Claim-context alignment scoring
- Inconsistency detection

## The Innovation: Soft Failures

### Addressing Non-Deterministic Evaluation Reliability

Monte Carlo Data pioneered the "soft failure" concept to make non-deterministic testing practical in CI/CD:

**The Problem**
- Traditional CI/CD: Any test failure blocks merge (hard failure)
- Non-deterministic evaluations: Some spurious failures inevitable
- LLM-as-judge can hallucinate incorrect assessments
- Need for nuance in pass/fail decisions

**The Solution: Soft Failures**

Rather than binary pass/fail, introduce a graduated system:

**Score Ranges**
- **0 - 0.5**: Hard failure (definitely wrong)
- **0.5 - 0.8**: Soft failure (uncertain/borderline)
- **0.8 - 1.0**: Pass (clearly correct)

**Aggregation Rules**
- Individual soft failures don't block merges
- Multiple soft failures trigger aggregate hard failure
- Example: ≥33% soft failures = hard failure
- Or: >2 total soft failures = hard failure

**Benefits**
- Allows breathing room for non-determinism
- Prevents spurious failures from blocking development
- Still catches genuine quality issues
- Enables continuous integration for agents

### Implementing Soft Failures

**Threshold Configuration**
```yaml
evaluation:
  hard_fail_threshold: 0.5
  pass_threshold: 0.8
  soft_fail_limits:
    percentage: 0.33
    absolute_count: 2
```

**Decision Logic**
1. Run evaluation suite
2. Calculate individual scores
3. Categorize as hard fail, soft fail, or pass
4. Check soft fail limits
5. If limits exceeded → hard fail overall
6. Otherwise → allow merge

### Complementary Strategies

**Automatic Retries**
- Trigger re-evaluation when aggregate soft failures occur
- ~10% of tests produce spurious results
- Single retry often resolves false negatives
- Assume one-time random effect if retry passes

**Explanation Requirements**
- Every LLM-judge must provide scoring rationale
- Helps build trust in evaluations
- Speeds debugging when failures occur
- Enables evaluation quality assessment

**Evaluating the Evaluators**
- Run evaluations multiple times
- Measure consistency and variance
- Remove or revise flaky evaluations
- Track evaluator reliability over time

## Hybrid Evaluation Strategies

### Combining Deterministic and Non-Deterministic Methods

The most robust evaluation frameworks use both approaches:

**Layered Evaluation Architecture**

1. **First Pass: Deterministic Filters**
   - Quick, cheap format validation
   - Clear rule-based checks
   - Filter obvious failures
   - Reduce expensive LLM-as-judge calls

2. **Second Pass: Non-Deterministic Assessment**
   - Semantic quality evaluation
   - Contextual appropriateness
   - Reasoning path analysis
   - Subjective criteria scoring

3. **Final Pass: Human Review**
   - Sample-based quality checks
   - Low-confidence evaluation review
   - Edge case analysis
   - Evaluator calibration

**Example: Tool Evaluation Pipeline**

```
Input: Agent execution trace

↓ Deterministic Check
├─ Were any tools called? (yes/no)
├─ Were forbidden tools avoided? (yes/no)
├─ Are parameters well-formed? (yes/no)
↓

↓ Non-Deterministic Check
├─ LLM-as-judge: Was right tool selected? (0-1 score)
├─ LLM-as-judge: Were parameters semantically correct? (0-1 score)
├─ LLM-as-judge: Was sequence logical? (0-1 score)
↓

↓ Aggregation
└─ Combine scores → Hard fail / Soft fail / Pass
```

### Choosing the Right Approach

**Use Deterministic When**:
- Ground truth is clear and unambiguous
- Format and structure matter
- Speed and cost are priorities
- Reproducibility is critical
- Simple rules can capture requirements

**Use Non-Deterministic When**:
- Semantic understanding required
- Multiple valid outputs exist
- Subjective quality matters
- Context and nuance important
- No clear ground truth available

**Use Hybrid When**:
- Complex multi-faceted evaluation needed
- Both objective and subjective criteria exist
- Need balance of speed and depth
- Production deployment requires confidence

## Managing Variability in Evaluation

### Statistical Approaches

**Multiple Run Analysis**
- Execute same test multiple times
- Compute success rate distribution
- Report confidence intervals
- Flag high-variance behaviors

**Pass@k Metrics**
- Run test k times
- Success if any run passes
- Useful for consistency evaluation
- Example: Pass@5 measures reliability

**Convergence Testing**
- Run agent on similar queries
- Track minimum steps to solution
- Calculate convergence score: Σ(min steps / actual steps)
- Measures path optimization

### Variance Reduction Techniques

**Controlled Randomness**
- Set temperature to 0 for reproducibility when possible
- Use fixed random seeds in testing
- Control sampling parameters
- Limit sources of non-determinism

**Evaluation Stabilization**
- Average scores across multiple runs
- Use ensemble of evaluators
- Require consistent results across runs
- Weight by evaluator confidence

**Contextual Anchoring**
- Provide detailed rubrics to LLM-judges
- Include examples of good and bad outputs
- Use structured evaluation prompts
- Chain-of-thought reasoning in evaluation

## Best Practices for Non-Deterministic Evaluation

### 1. Accept and Embrace Uncertainty

- Don't force deterministic frameworks onto non-deterministic systems
- Design evaluation processes that account for variability
- Use statistical thinking (distributions, not point estimates)
- Build confidence through multiple evidence sources

### 2. Implement Soft Failures

- Introduce graduated scoring (hard fail / soft fail / pass)
- Set aggregate thresholds for soft failures
- Allow breathing room for evaluation variance
- Maintain quality gates without excessive brittleness

### 3. Automate Retry Mechanisms

- Automatically re-run on aggregate soft failures
- Account for spurious evaluation errors
- Reduce false negatives blocking development
- Track retry rates to identify flaky evaluators

### 4. Require Explanations

- Make evaluators explain their scores
- Build trust through transparency
- Enable faster debugging
- Support evaluator quality assessment

### 5. Continuously Improve Evaluators

- Treat evaluators as code requiring maintenance
- Run evaluators multiple times to assess consistency
- Remove or revise unreliable evaluations
- Validate against human judgment periodically

### 6. Balance Cost and Coverage

**Localized Testing**
- Don't spin up full agent for unit-level tests
- Provide context that subagents would have collected
- Test components in isolation where possible
- Reduce redundant expensive evaluations

**Conservative Triggers**
- Run full evaluation suite selectively
- Trigger on specific component changes
- Balance thoroughness with cost
- Target 1:1 ratio of evaluation to operation cost

## Real-World Application: Case Study

### Monte Carlo's Troubleshooting Agent Evaluation

**Challenge**: Complex multi-agent system with hundreds of sub-agents for root cause analysis of data incidents.

**Evaluation Categories**:
1. **Semantic Distance** (Non-Deterministic)
   - LLM-as-judge comparing expected vs. actual responses
   - 0-1 similarity scoring
   - Accounts for different wording, same meaning

2. **Groundedness** (Non-Deterministic)
   - LLM-as-judge checking context usage
   - Ensures retrieval and proper use of information
   - Detects when agent should decline to answer

3. **Tool Usage** (Hybrid)
   - Deterministic: Correct tools available and called
   - Non-Deterministic: LLM-as-judge for appropriateness

**Soft Failure Implementation**:
- Scores < 0.5: Hard failure
- Scores 0.5-0.8: Soft failure
- Soft fail limits: 33% rate or 2 absolute count
- Automatic retry on aggregate soft failure

**Results**: Successfully enabled CI/CD for non-deterministic agentic system with reliable quality gates.

## Conclusion

The shift from deterministic to non-deterministic evaluation represents a fundamental paradigm change in software testing. AI agents require evaluation approaches that embrace variability while maintaining quality standards. By combining deterministic methods for objective criteria, non-deterministic approaches for semantic understanding, soft failure concepts for practical CI/CD integration, and statistical thinking for variance management, teams can build robust evaluation frameworks that work in the real world of unpredictable AI agents.

The key insight is that we're testing for hallucinations with evaluations that can hallucinate—and accounting for this reality through innovations like soft failures makes reliable evaluation practical despite inherent uncertainty.

---

## References

1. Monte Carlo Data. (2025). "AI Agent Evaluation: 5 Lessons Learned The Hard Way." Retrieved from https://www.montecarlodata.com/blog-ai-agent-evaluation/

2. DeepEval. (2025). "AI Agent Evaluation Guide." Retrieved from https://deepeval.com/guides/guides-ai-agent-evaluation

3. Orq.ai. (2025). "Agent Evaluation in 2025: Complete Guide." Retrieved from https://orq.ai/blog/agent-evaluation

4. Leanware. (2025). "Agent Evaluation Frameworks: Methods, Metrics & Best Practices." Retrieved from https://www.leanware.co/insights/agent-evaluation-frameworks-methods-metrics-best-practices

5. Arize AI. (2025). "τ-bench: Tool-Agent-User Interaction Consistency." arXiv:2406.12045. Retrieved from https://doi.org/10.48550/arXiv.2406.12045
