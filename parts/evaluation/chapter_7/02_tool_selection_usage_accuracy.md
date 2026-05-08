# 7.2 Tool Selection and Usage Accuracy

## Introduction

As AI agents evolve from simple conversational interfaces to sophisticated autonomous systems, their ability to correctly select and use tools becomes paramount. While task completion metrics (Chaptear 7.1) establish whether an agent achieved its goal, tool selection and usage accuracy evaluates *how* the agent accomplished the task—specifically, whether it chose appropriate tools from available options and invoked them correctly with proper parameters.

The challenge of tool evaluation has grown exponentially as agent ecosystems expand. Modern agents often have access to dozens or even thousands of tools, from simple calculators to complex API integrations. Each tool call represents a decision point where the agent must: (1) determine if a tool is needed, (2) select the correct tool from alternatives, (3) extract appropriate parameters from context, and (4) format the call correctly for execution. Failure at any stage results in incorrect outcomes, wasted resources, or system errors.

This document explores the comprehensive landscape of tool evaluation, from fundamental metrics like tool correctness to advanced techniques like AST-level validation and router evaluation. Understanding tool usage accuracy enables teams to diagnose agent failures, optimize tool libraries, and build more reliable autonomous systems.

## Fundamental Tool Evaluation Metrics

### ToolCorrectnessMetric

DeepEval's ToolCorrectnessMetric provides component-level evaluation focused on whether the agent selected the correct tool for the task. Unlike end-to-end metrics that evaluate final outcomes, this metric isolates the tool selection decision:

**Evaluation Criteria**:
- **Tool name correctness**: Did the agent call the intended function/API?
- **Tool necessity**: Was a tool call actually required for this step?
- **Tool availability awareness**: Did the agent attempt to use non-existent tools?

The metric operates within DeepEval's trace evaluation framework, requiring the `@observe` decorator to capture tool calls during agent execution. This enables analyzing the reasoning layer (why the agent chose a particular tool) separately from the execution layer (whether the tool worked correctly).

ToolCorrectnessMetric proves especially valuable for debugging agent behavior when task completion fails. An agent might correctly understand user intent but consistently select the wrong tools, indicating issues with tool descriptions, prompt engineering, or the underlying model's reasoning capabilities.

### ArgumentCorrectnessMetric

Even when agents select the correct tool, they must extract and format parameters accurately. DeepEval's ArgumentCorrectnessMetric evaluates parameter accuracy through:

**Parameter Validation**:
- **Required parameters**: Are all mandatory arguments present?
- **Type correctness**: Do argument types match function signatures?
- **Value appropriateness**: Are argument values reasonable for the context?
- **Optional parameters**: Are optional arguments used appropriately?

Consider a weather API requiring `location` (string) and optionally `units` (enum: 'metric'|'imperial'). ArgumentCorrectnessMetric would catch failures like:

```python
# Incorrect - missing required parameter
get_weather(units="metric")

# Incorrect - wrong type
get_weather(location=12345, units="metric")

# Incorrect - invalid enum value
get_weather(location="Boston", units="celsius")

# Correct
get_weather(location="Boston", units="metric")
```

Parameter extraction proves particularly challenging when:
- Multiple similar parameters exist across different tools
- User input is ambiguous or incomplete
- Parameter formats vary (dates, currencies, identifiers)
- Default values must be inferred from context

Tracking argument correctness separately from tool selection enables targeted improvements. High tool correctness with low argument correctness suggests the agent understands tool purposes but struggles with parameter extraction—potentially addressable through better prompt engineering or few-shot examples.

### ToolCallAccuracyEvaluator

Microsoft's Azure AI Foundry SDK introduces the ToolCallAccuracyEvaluator, which provides threshold-based pass/fail assessment for tool usage. Unlike metric-based approaches that assign continuous scores, this evaluator produces binary outcomes suitable for automated testing:

**Evaluation Process**:
1. Compare expected tool calls (ground truth) with actual agent tool calls
2. Compute accuracy score (0.0-1.0 scale)
3. Apply threshold (default: 0.5) to determine pass/fail
4. Generate detailed reasoning explaining the assessment

The evaluator supports Azure's diverse tool ecosystem including:
- **File Search**: Semantic search across document collections
- **Azure AI Search**: Enterprise search integration
- **Bing Grounding**: Web search capabilities
- **SharePoint**: Document repository access
- **Code Interpreter**: Python execution environment
- **Fabric Data Agent**: Data analysis and querying
- **OpenAPI Tools**: REST API integrations
- **Function Tools**: Custom function definitions

This broad tool support reflects production realities where agents must navigate heterogeneous tool ecosystems. The evaluator handles both simple function calls and complex multi-tool workflows, making it suitable for realistic agent evaluation.

**Integration with Reasoning Models**: Azure's evaluator explicitly supports advanced reasoning models like o3-mini, which employ deliberate planning before tool selection. The evaluator can analyze both the planning phase (tool selection reasoning) and execution phase (actual tool calls), providing visibility into whether failures occur during reasoning or execution.

## Function Calling Evaluation: The Berkeley Approach

### Berkeley Function Calling Leaderboard (BFCL)

The Berkeley Function Calling Leaderboard represents the most comprehensive standardized evaluation of agent function calling capabilities. With over 2,000 evaluation data points across multiple programming languages, BFCL establishes industry benchmarks for tool usage accuracy.

**BFCL Evaluation Methodology**:

**1. AST-Level Evaluation (Abstract Syntax Tree)**:

Rather than simple string matching, BFCL parses function calls into abstract syntax trees to enable semantic comparison. This approach recognizes that equivalent function calls can have different surface representations:

```python
# These are semantically equivalent
get_weather(location="Boston", units="metric", days=3)
get_weather(units="metric", location="Boston", days=3)
get_weather("Boston", units="metric", days=3)
```

AST evaluation checks:
- **Function name matching**: Exact function identifier correctness
- **Required parameter validation**: All mandatory parameters present
- **Parameter type checking**: Strict type validation (int vs float matters)
- **Parameter value correctness**: Semantic equivalence of argument values

The strict typing rules mean that `get_weather(days=3)` and `get_weather(days=3.0)` are considered different if the signature expects an integer. This strictness reflects production realities where type mismatches cause runtime errors.

**2. Executable Evaluation**:

BFCL goes beyond static analysis to actually execute function calls in sandboxed environments:

- **Exact Match**: Function output exactly matches expected output
- **Structural Match**: Output structure matches even if some values differ (e.g., timestamps)
- **Real-Time Match**: Output correctness considering dynamic data (e.g., current weather)

Executable evaluation catches issues invisible to AST analysis:
- Incorrect logic despite syntactically correct calls
- Side effects and state management problems
- Performance issues (timeouts, resource exhaustion)
- Error handling and exception management

**3. Multi-Language Support**:

BFCL evaluates function calling across:
- **Python**: Native function definitions and library calls
- **Java**: Method invocation with strong typing
- **JavaScript**: Function calls with loose typing
- **REST APIs**: HTTP request formatting and parameter encoding
- **SQL**: Query construction and parameterization

This multi-language coverage recognizes that production agents must interface with diverse systems. An agent might need to call Python libraries for data processing, Java services for business logic, REST APIs for external integrations, and SQL databases for data access.

**4. Leaderboard Categories**:

BFCL organizes evaluation into nine distinct categories:

- **Simple Function**: Single function calls with basic parameters
- **Multiple Function**: Choosing among several similar functions
- **Parallel Function**: Calling multiple functions simultaneously
- **Parallel Multiple Function**: Complex multi-tool orchestration
- **Function Relevance**: Determining when tools aren't needed
- **REST API**: HTTP endpoint interaction
- **SQL**: Database query construction
- **Java**: Strongly-typed method invocation
- **JavaScript**: Loosely-typed function calling

State-of-the-art models show dramatically different performance across categories. A model might achieve 95% accuracy on simple functions but only 60% on parallel multiple function scenarios, revealing limitations in complex orchestration.

**5. Cost and Latency Tracking**:

BFCL tracks operational metrics alongside accuracy:
- Token consumption per function call decision
- End-to-end latency for tool selection and invocation
- API cost for models requiring paid access

These metrics inform real-world deployment decisions. A model with 98% accuracy might be impractical if it consumes 10x more tokens than a 93% accurate alternative.

### Gorilla OpenFunctions-v2 and Large Tool Libraries

A critical challenge addressed by BFCL is tool selection from large libraries. The Gorilla project's OpenFunctions-v2 dataset tests agents against 16,000+ available functions, simulating realistic enterprise environments where agents must:

1. **Semantic search**: Identify relevant tools from thousands of options
2. **Disambiguation**: Distinguish between similar-sounding tools
3. **Composition awareness**: Understand when multiple tools must be combined
4. **Constraint satisfaction**: Select tools that meet all requirements

Evaluation at this scale reveals different failure modes than small tool libraries:
- **Retrieval failures**: Missing relevant tools during initial search
- **Ranking errors**: Selecting suboptimal tools when better options exist
- **Combinatorial explosion**: Failing to consider tool combinations
- **Description dependence**: Over-relying on tool documentation quality

These insights inform practical design decisions about tool organization, documentation standards, and retrieval mechanisms for production agent systems.

## Router and Skill Evaluation

### Router Evaluation Framework

Arize's router evaluation framework addresses multi-agent systems where a routing layer directs queries to specialized sub-agents or skills. Router evaluation comprises two distinct components:

**1. Skill Selection Accuracy**:

Did the router direct the query to the correct specialized agent?

```
Example:
Query: "What's the weather in Tokyo?"
Available Skills: [WeatherAgent, NewsAgent, CalculatorAgent]
Correct Routing: WeatherAgent
Evaluation: Binary success/failure
```

Skill selection operates at a higher abstraction level than tool selection. Rather than choosing specific functions, the router categorizes queries into capability domains. This hierarchical approach enables scaling to hundreds of specialized skills without overwhelming individual agents with massive tool libraries.

**2. Parameter Extraction Accuracy**:

Beyond routing to the correct skill, did the router extract the necessary parameters for the target agent?

```
Example:
Query: "What's the weather in Tokyo tomorrow?"
Extracted Parameters: {
  "location": "Tokyo",
  "time": "tomorrow"
}
Evaluation: Check completeness and correctness
```

Parameter extraction evaluation uses metrics like:
- **Completeness**: Proportion of required parameters extracted
- **Precision**: Proportion of extracted parameters that are correct
- **Type correctness**: Parameter types match skill requirements

**Parameter Overlap Testing**: Arize's evaluation specifically handles scenarios where multiple skills accept similar parameters:

```
Query: "Book a flight to Paris and find hotels there"
Skills: [FlightBooker, HotelFinder]
Both require "location" parameter

Challenge: Correctly extract parameters for multiple skills
- FlightBooker: {destination: "Paris"}
- HotelFinder: {location: "Paris"}
```

Router evaluation reveals whether agents can handle ambiguous queries requiring multiple skills with overlapping parameter spaces—a common production scenario.

### Built-in Evaluators for Tool Call Accuracy

Arize provides LLM-as-judge templates specifically designed for tool usage assessment:

**Tool Selection Evaluator**:
```
Given the user query: {query}
Available tools: {tool_descriptions}
Agent selected: {selected_tool}

Rate the tool selection (1-5):
5: Optimal tool choice
4: Acceptable alternative exists but this works
3: Suboptimal but functional
2: Wrong tool, likely to fail
1: Completely inappropriate tool

Reasoning: [explanation]
```

**Parameter Extraction Evaluator**:
```
Given the selected tool: {tool_name}
Required parameters: {required_params}
Agent extracted: {extracted_params}

Evaluate parameter extraction:
- Missing required parameters: [list]
- Incorrect parameter values: [list]
- Incorrect parameter types: [list]
- Overall score (0-1): [score]
```

These LLM-based evaluators enable flexible assessment of subjective criteria like "appropriateness" while maintaining consistency across evaluations. However, they introduce costs and latency that may be prohibitive for large-scale evaluation, suggesting a tiered approach:
1. Fast deterministic metrics for development iteration
2. LLM-based evaluation for ambiguous cases
3. Human review for high-value or disputed evaluations

## Advanced Evaluation Techniques

### AST Correctness Beyond Function Names

While BFCL popularized AST-level evaluation, extending this approach reveals deeper insights:

**Argument Structure Analysis**:
- **Nested parameters**: Correctly handling complex object parameters
- **List/array arguments**: Proper collection construction
- **Callback functions**: Function-as-argument correctness
- **Variadic arguments**: Handling variable-length parameter lists

**Type System Compliance**:
- **Generic types**: Correct type parameter specification
- **Union types**: Choosing appropriate type from alternatives
- **Optional chaining**: Proper handling of nullable parameters
- **Type coercion**: Understanding implicit conversions

**Error Handling Patterns**:
- **Exception catching**: Appropriate try-catch structure
- **Fallback logic**: Alternate paths for tool failures
- **Validation**: Input checking before tool invocation
- **Retry mechanisms**: Exponential backoff and retry logic

Advanced AST evaluation moves beyond "did the agent call the right function?" to "did the agent invoke the function in a production-quality manner?" This distinction matters for agents transitioning from prototypes to production systems.

### Cross-Tool Dependency Analysis

Many real-world tasks require tool sequences with dependencies:

```
Task: "Send me an email with yesterday's sales data"

Required Sequence:
1. get_sales_data(date="yesterday") → data
2. format_report(data=data) → report
3. send_email(body=report, recipient="user")

Evaluation Points:
- Tool selection: All three tools identified
- Sequencing: Correct execution order
- Data flow: Output of step 1 feeds step 2, etc.
- Error propagation: Handling if step 1 fails
```

**Dependency Graph Correctness**: Evaluating whether agents construct valid dependency graphs for multi-tool workflows:
- No circular dependencies
- All required inputs satisfied before execution
- Parallelizable steps identified correctly
- Sequential constraints respected

**Data Transformation Tracking**: Ensuring data flows correctly between tools:
- Type compatibility between tool outputs and inputs
- Necessary transformations applied (e.g., JSON serialization)
- No data loss during handoffs
- Proper handling of partial results

### Tool Documentation Sensitivity

Agent tool selection accuracy depends heavily on tool documentation quality. Sensitivity analysis reveals:

**Description Completeness Impact**:
- **Minimal descriptions** (name only): Baseline agent performance
- **Single-sentence descriptions**: Improvement margin
- **Detailed descriptions** (parameters, examples): Maximum performance
- **Adversarial descriptions** (misleading): Robustness testing

**Systematic testing** across documentation quality levels reveals whether agents:
- Overfit to specific documentation styles
- Generalize from examples appropriately
- Handle ambiguous or inconsistent documentation
- Recover when tool descriptions are wrong

This analysis informs documentation standards for production tool libraries, identifying minimum documentation requirements for reliable agent performance.

### Real-World Tool Complexity

Production environments introduce complexities absent from synthetic benchmarks:

**API Versioning**:
- Multiple versions of the same tool available
- Deprecated endpoints that still function
- Breaking changes between versions
- Backward compatibility requirements

**Authentication and Authorization**:
- OAuth flows for authenticated calls
- API key management
- Permission-based tool availability
- Rate limiting and quota management

**Error Modes and Reliability**:
- Transient failures requiring retries
- Partial results for large requests
- Timeout handling for long-running operations
- Graceful degradation when tools are unavailable

Evaluation must extend beyond happy-path scenarios to test agent behavior under realistic operational constraints.

## Production Monitoring and Operational Metrics

### Tool Usage Pattern Analysis

Production monitoring reveals actual tool usage patterns:

**Frequency Analysis**:
- Which tools are most commonly used?
- Are rarely-used tools necessary or removable?
- Do agents over-rely on specific tools?
- Are there tools that should be used but aren't?

**Temporal Patterns**:
- Tool usage by time of day or week
- Seasonal variations in tool selection
- Correlation with external events
- Drift over time in tool preferences

**Failure Mode Classification**:
- Tool selection errors (wrong tool chosen)
- Parameter extraction errors (right tool, wrong parameters)
- Execution errors (tool called correctly but failed)
- Timeout errors (tool too slow)

Categorizing failures enables targeted improvements. If 80% of failures are parameter extraction errors, focus on prompt engineering or adding parameter extraction examples rather than expanding the tool library.

### Cost and Efficiency Optimization

Tool usage has direct operational costs:

**Token Consumption Patterns**:
- Tokens spent on tool descriptions in prompts
- Tokens for tool call reasoning and planning
- Variation in token usage across tools
- Optimization opportunities (shorter descriptions, better organization)

**Latency Decomposition**:
```
Total Latency = Planning Time + Tool Selection Time + 
                Tool Execution Time + Result Processing Time
```

Breaking down latency reveals bottlenecks. An agent might have fast tool selection but slow tool execution, suggesting the need for:
- Faster tool implementations
- Caching for frequently-accessed data
- Parallel tool execution where possible
- Timeout tuning for long-running operations

**Cost per Task Completion**:
```
Cost = (Model API Cost × Tokens Used) + 
       (Tool API Costs) + 
       (Compute Costs)
```

Tracking costs per successful task enables comparing different agent architectures:
- Small model with more tool calls vs. large model with fewer calls
- End-to-end reasoning vs. explicit planning + execution phases
- Single generalist model vs. router + specialized models

### Tool Library Evolution

As agents evolve, tool libraries must evolve with them:

**Tool Addition Process**:
1. Identify capability gaps from failure analysis
2. Develop or integrate new tools
3. Write descriptions and examples
4. Evaluate impact on existing tool selection
5. Monitor adoption rates and accuracy

**Tool Deprecation Process**:
1. Identify underutilized or problematic tools
2. Analyze failures if tool is removed
3. Migrate functionality to better alternatives
4. Phase out gradually with monitoring
5. Remove and observe impact on success rates

**Version Management**:
- A/B testing tool versions (v1 vs. v2)
- Gradual rollout of updated tools
- Rollback capabilities for failed updates
- Documentation versioning synchronized with code

## Best Practices and Implementation Guidelines

### Tool Library Design Principles

**Principle 1: Clear Naming Conventions**

Tool names should be self-descriptive:
```
Good: get_weather_forecast, search_customer_records
Poor: fetch_data, query_system
```

Consistent naming patterns enable agents to infer tool purposes even with minimal descriptions.

**Principle 2: Parameter Design**

- **Required vs. optional**: Minimize required parameters
- **Default values**: Provide sensible defaults for optional parameters
- **Type clarity**: Use specific types (datetime, not string)
- **Validation**: Fail fast with clear error messages

**Principle 3: Tool Granularity**

Balance between:
- **Fine-grained tools**: Maximum flexibility, complex orchestration
- **Coarse-grained tools**: Simpler invocation, less flexibility

Rule of thumb: One tool per distinct business capability.

**Principle 4: Documentation Standards**

Mandatory documentation components:
- **Purpose**: What does this tool do?
- **Parameters**: Name, type, description, examples for each
- **Returns**: Output format and type
- **Examples**: 2-3 realistic usage examples
- **Error conditions**: Common failure modes

### Evaluation Dataset Construction

**Coverage Requirements**:

Tool evaluation datasets should include:
- **Positive examples**: Correct tool selection scenarios
- **Negative examples**: Cases where tools shouldn't be used
- **Ambiguous cases**: Multiple reasonable tool choices
- **Multi-tool scenarios**: Tasks requiring tool composition
- **Edge cases**: Unusual but valid tool usage patterns

**Ground Truth Quality**:

For each evaluation example, specify:
- **Expected tool(s)**: Which tools should be called
- **Expected parameters**: Full parameter dictionaries
- **Acceptable alternatives**: Valid alternative tool choices
- **Common mistakes**: Known failure patterns to watch for

**Dataset Maintenance**:

Evaluation datasets require ongoing maintenance:
- Add production failures as new test cases
- Update examples when tools change
- Remove deprecated tool references
- Balance dataset across tool types and complexities

### Continuous Improvement Loop

Establish a systematic improvement cycle:

```
1. Monitor production tool usage and failures
2. Analyze failure patterns (selection vs. parameter errors)
3. Identify improvement opportunities:
   - Better tool descriptions
   - Additional examples in prompts
   - Tool library reorganization
   - Model fine-tuning with tool usage data
4. Implement changes
5. Evaluate impact on held-out test set
6. Deploy if improvement is statistically significant
7. Monitor production impact
8. Iterate
```

This cycle ensures tool evaluation drives continuous agent improvement rather than one-time assessment.

## Bibliography

1. DeepEval Documentation. (2025). "AI Agent Evaluation: Tool and Argument Correctness Metrics." Retrieved from https://deepeval.com/guides/guides-ai-agent-evaluation

2. Microsoft Azure AI. (2025). "Evaluate Your AI Agents Locally: ToolCallAccuracy Evaluator." Retrieved from https://learn.microsoft.com/en-us/azure/ai-foundry/how-to/develop/agent-evaluate-sdk

3. Arize AI. (2025). "Agent Evaluation: Router and Skill Assessment Frameworks." Retrieved from https://arize.com/ai-agents/agent-evaluation/

4. Patil, S. G., Mao, H., Ji, C. C., Yan, F., Suresh, V., Stoica, I., & Gonzalez, J. E. (2024). "The Berkeley Function Calling Leaderboard (BFCL)." Retrieved from https://gorilla.cs.berkeley.edu/blogs/8_berkeley_function_calling_leaderboard.html

5. Berkeley Gorilla Project. (2025). "Gorilla: Large Language Model Connected with Massive APIs." Retrieved from https://gorilla.cs.berkeley.edu/

6. OpenAI. (2024). "Function Calling and Tools." Retrieved from https://platform.openai.com/docs/guides/function-calling
