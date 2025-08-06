defmodule Toolbox.Category do
  use Ecto.Type

  defstruct [:id, :name, :description, :permalink]

  @compile {:inline, all: 0}

  # Ecto Type implementation
  def type, do: :integer

  def cast(%__MODULE__{id: id}), do: {:ok, id}
  def cast(id) when is_integer(id), do: {:ok, id}
  def cast(_), do: :error

  def load(id) when is_integer(id) do
    case find_by_id(id) do
      nil -> :error
      category -> {:ok, category}
    end
  end

  def load(_), do: :error

  def dump(%__MODULE__{id: id}), do: {:ok, id}
  def dump(id) when is_integer(id), do: {:ok, id}
  def dump(_), do: :error

  defp find_by_id(id) do
    Enum.find(all(), &(&1.id == id))
  end

  def all do
    [
      %__MODULE__{
        id: 1,
        name: "Actors",
        description:
          "Libraries implementing the Actor model for concurrent programming with isolated processes that communicate via message passing",
        permalink: "actors"
      },
      %__MODULE__{
        id: 2,
        name: "Algorithms and Data structures",
        description:
          "Implementations of algorithms and data structures optimized for Elixir's functional programming paradigm",
        permalink: "algorithms-and-data-structures"
      },
      %__MODULE__{
        id: 4,
        name: "Artificial Intelligence",
        description:
          "Machine learning, neural networks, and AI-related libraries for Elixir including Nx and Axon",
        permalink: "artificial-intelligence"
      },
      %__MODULE__{
        id: 5,
        name: "Audio and Sounds",
        description:
          "Libraries for audio processing, sound generation, and multimedia applications",
        permalink: "audio-and-sounds"
      },
      %__MODULE__{
        id: 6,
        name: "Authentication",
        description:
          "Libraries for user authentication, session management, and identity verification",
        permalink: "authentication"
      },
      %__MODULE__{
        id: 7,
        name: "Authorization",
        description:
          "Access control and permission management libraries for securing applications",
        permalink: "authorization"
      },
      %__MODULE__{
        id: 8,
        name: "Behaviours and Interfaces",
        description:
          "OTP behaviours and interface definitions for creating reusable and standardized components",
        permalink: "behaviours-and-interfaces"
      },
      %__MODULE__{
        id: 9,
        name: "Benchmarking",
        description:
          "Performance testing and benchmarking tools for measuring Elixir application performance",
        permalink: "benchmarking"
      },
      %__MODULE__{
        id: 10,
        name: "Bittorrent",
        description:
          "Libraries for implementing BitTorrent protocol and peer-to-peer file sharing",
        permalink: "bittorrent"
      },
      %__MODULE__{
        id: 11,
        name: "BSON",
        description:
          "Libraries for Binary JSON encoding and decoding, commonly used with MongoDB",
        permalink: "bson"
      },
      %__MODULE__{
        id: 12,
        name: "Build Tools",
        description:
          "Tools for building, compiling, and managing Elixir projects beyond the standard Mix tool",
        permalink: "build-tools"
      },
      %__MODULE__{
        id: 13,
        name: "Caching",
        description:
          "In-memory and distributed caching solutions for improving application performance",
        permalink: "caching"
      },
      %__MODULE__{
        id: 14,
        name: "Chatting",
        description:
          "Real-time messaging and chat application libraries leveraging Elixir's concurrency",
        permalink: "chatting"
      },
      %__MODULE__{
        id: 15,
        name: "Cloud Infrastructure and Management",
        description:
          "Tools for cloud deployment, infrastructure as code, and cloud service integrations",
        permalink: "cloud-infrastructure-and-management"
      },
      %__MODULE__{
        id: 16,
        name: "Code Analysis",
        description: "Static analysis tools, linters, and code quality assessment libraries",
        permalink: "code-analysis"
      },
      %__MODULE__{
        id: 17,
        name: "Command Line Applications",
        description: "Libraries for building CLI tools and command-line interfaces",
        permalink: "command-line-applications"
      },
      %__MODULE__{
        id: 18,
        name: "Configuration",
        description:
          "Application configuration management and environment-specific settings handling",
        permalink: "configuration"
      },
      %__MODULE__{
        id: 19,
        name: "Cryptography",
        description: "Encryption, hashing, and cryptographic utilities for secure applications",
        permalink: "cryptography"
      },
      %__MODULE__{
        id: 20,
        name: "CSV",
        description: "Comma-separated values parsing and generation libraries",
        permalink: "csv"
      },
      %__MODULE__{
        id: 21,
        name: "Date and Time",
        description: "Date, time, and timezone handling libraries including calendar operations",
        permalink: "date-and-time"
      },
      %__MODULE__{
        id: 22,
        name: "Debugging",
        description:
          "Debugging tools, profilers, and development aids for troubleshooting Elixir applications",
        permalink: "debugging"
      },
      %__MODULE__{
        id: 23,
        name: "Deployment",
        description:
          "Application deployment tools, containerization, and production environment setup",
        permalink: "deployment"
      },
      %__MODULE__{
        id: 24,
        name: "Documentation",
        description:
          "Documentation generation tools and libraries for creating API docs and guides",
        permalink: "documentation"
      },
      %__MODULE__{
        id: 25,
        name: "Domain-specific language",
        description: "Tools for creating DSLs and domain-specific syntax within Elixir",
        permalink: "domain-specific-language"
      },
      %__MODULE__{
        id: 26,
        name: "ECMAScript",
        description: "JavaScript integration and ECMAScript compatibility libraries",
        permalink: "ecmascript"
      },
      %__MODULE__{
        id: 27,
        name: "Elasticsearch",
        description: "Integration libraries for Elasticsearch search and analytics engine",
        permalink: "elasticsearch"
      },
      %__MODULE__{
        id: 28,
        name: "Email",
        description: "Email sending, receiving, and processing libraries including SMTP clients",
        permalink: "email"
      },
      %__MODULE__{
        id: 29,
        name: "Embedded Systems",
        description:
          "Libraries for IoT and embedded device development, including Nerves framework",
        permalink: "embedded-systems"
      },
      %__MODULE__{
        id: 30,
        name: "Encoding and Compression",
        description: "Data encoding, decoding, and compression utilities for various formats",
        permalink: "encoding-and-compression"
      },
      %__MODULE__{
        id: 31,
        name: "Errors and Exception Handling",
        description: "Error tracking, exception handling, and fault tolerance utilities",
        permalink: "errors-and-exception-handling"
      },
      %__MODULE__{
        id: 32,
        name: "Event Handling",
        description: "Event-driven programming libraries and event sourcing implementations",
        permalink: "eventhandling"
      },
      %__MODULE__{
        id: 34,
        name: "Feature Flags and Toggles",
        description: "Feature flag management for gradual rollouts and A/B testing",
        permalink: "feature-flags-and-toggles"
      },
      %__MODULE__{
        id: 35,
        name: "Feeds",
        description: "RSS, Atom, and other feed parsing and generation libraries",
        permalink: "feeds"
      },
      %__MODULE__{
        id: 36,
        name: "Files and Directories",
        description:
          "File system operations, directory traversal, and file manipulation utilities",
        permalink: "files-and-directories"
      },
      %__MODULE__{
        id: 37,
        name: "Formulars",
        description: "Form handling and validation libraries for web applications",
        permalink: "formulars"
      },
      %__MODULE__{
        id: 38,
        name: "Framework Components",
        description: "Reusable components and plugins for web frameworks like Phoenix",
        permalink: "framework-components"
      },
      %__MODULE__{
        id: 39,
        name: "Frameworks",
        description: "Web frameworks and application frameworks beyond Phoenix",
        permalink: "frameworks"
      },
      %__MODULE__{
        id: 40,
        name: "Games",
        description: "Game development libraries and engines for creating games in Elixir",
        permalink: "games"
      },
      %__MODULE__{
        id: 41,
        name: "Geolocation",
        description: "Geographic data processing, mapping, and location-based services",
        permalink: "geolocation"
      },
      %__MODULE__{
        id: 42,
        name: "GUI",
        description: "Graphical user interface libraries for desktop application development",
        permalink: "gui"
      },
      %__MODULE__{
        id: 43,
        name: "Hardware",
        description: "Hardware interaction libraries for sensors, GPIO, and device control",
        permalink: "hardware"
      },
      %__MODULE__{
        id: 44,
        name: "HTML",
        description: "HTML parsing, generation, and manipulation libraries",
        permalink: "html"
      },
      %__MODULE__{
        id: 45,
        name: "HTTP",
        description: "HTTP protocol libraries and utilities for web communication",
        permalink: "http"
      },
      %__MODULE__{
        id: 46,
        name: "HTTP Client",
        description: "HTTP client libraries for making web requests and API calls",
        permalink: "http-client"
      },
      %__MODULE__{
        id: 47,
        name: "HTTP Server",
        description: "HTTP server implementations and web server utilities",
        permalink: "http-server"
      },
      %__MODULE__{
        id: 48,
        name: "Images",
        description: "Image processing, manipulation, and format conversion libraries",
        permalink: "images"
      },
      %__MODULE__{
        id: 49,
        name: "Instrumenting / Monitoring",
        description:
          "Application performance monitoring, metrics collection, and observability tools",
        permalink: "instrumenting-monitoring"
      },
      %__MODULE__{
        id: 50,
        name: "JSON",
        description: "JSON encoding, decoding, and manipulation libraries",
        permalink: "json"
      },
      %__MODULE__{
        id: 51,
        name: "Languages",
        description: "Language processing tools and programming language implementations",
        permalink: "languages"
      },
      %__MODULE__{
        id: 52,
        name: "Lexical Analysis",
        description: "Tokenization, parsing, and lexical analysis tools for language processing",
        permalink: "lexical-analysis"
      },
      %__MODULE__{
        id: 53,
        name: "Logging",
        description:
          "Logging frameworks and structured logging utilities for application monitoring",
        permalink: "logging"
      },
      %__MODULE__{
        id: 54,
        name: "Macros",
        description: "Metaprogramming utilities and macro libraries for code generation",
        permalink: "macros"
      },
      %__MODULE__{
        id: 55,
        name: "Markdown",
        description: "Markdown parsing and HTML generation from Markdown content",
        permalink: "markdown"
      },
      %__MODULE__{
        id: 56,
        name: "Miscellaneous",
        description: "Utility libraries and tools that don't fit into other specific categories",
        permalink: "miscellaneous"
      },
      %__MODULE__{
        id: 57,
        name: "Native Implemented Functions",
        description: "NIFs (Native Implemented Functions) for integrating C/C++ code with Elixir",
        permalink: "native-implemented-functions"
      },
      %__MODULE__{
        id: 58,
        name: "Natural Language Processing (NLP)",
        description:
          "Text processing, sentiment analysis, and natural language understanding libraries",
        permalink: "natural-language-processing-nlp"
      },
      %__MODULE__{
        id: 59,
        name: "Networking",
        description:
          "Network programming libraries for sockets, protocols, and network communication",
        permalink: "networking"
      },
      %__MODULE__{
        id: 60,
        name: "Office",
        description:
          "Office document processing including Excel, Word, and PowerPoint file handling",
        permalink: "office"
      },
      %__MODULE__{
        id: 61,
        name: "ORM and Datamapping",
        description: "Object-relational mapping and database abstraction layers, primarily Ecto",
        permalink: "orm-and-datamapping"
      },
      %__MODULE__{
        id: 62,
        name: "OTP",
        description: "Open Telecom Platform libraries and OTP behavior implementations",
        permalink: "otp"
      },
      %__MODULE__{
        id: 63,
        name: "Package Management",
        description: "Dependency management and package distribution tools beyond Hex",
        permalink: "package-management"
      },
      %__MODULE__{
        id: 64,
        name: "PDF",
        description: "PDF document generation, parsing, and manipulation libraries",
        permalink: "pdf"
      },
      %__MODULE__{
        id: 65,
        name: "Phoenix",
        description: "The Phoenix web framework and related Phoenix ecosystem libraries",
        permalink: "phoenix"
      },
      %__MODULE__{
        id: 66,
        name: "Forms",
        description:
          "Form builders, validators, and form handling utilities for web applications",
        permalink: "forms"
      },
      %__MODULE__{
        id: 67,
        name: "Protocols",
        description: "Protocol definitions and implementations for polymorphic behavior",
        permalink: "protocols"
      },
      %__MODULE__{
        id: 68,
        name: "Queue",
        description: "Message queuing systems and background job processing libraries",
        permalink: "queue"
      },
      %__MODULE__{
        id: 69,
        name: "QUIC",
        description: "QUIC protocol implementations for fast, secure transport",
        permalink: "quic"
      },
      %__MODULE__{
        id: 70,
        name: "Release Management",
        description: "Application release building, versioning, and deployment automation",
        permalink: "release-management"
      },
      %__MODULE__{
        id: 71,
        name: "REST and API",
        description: "RESTful API development tools and API client libraries",
        permalink: "rest-and-api"
      },
      %__MODULE__{
        id: 72,
        name: "Scheduling",
        description: "Job scheduling, cron-like functionality, and periodic task execution",
        permalink: "scheduling"
      },
      %__MODULE__{
        id: 73,
        name: "Search",
        description: "Full-text search engines and search functionality implementations",
        permalink: "search"
      },
      %__MODULE__{
        id: 74,
        name: "Security",
        description: "Security tools, vulnerability scanners, and security-focused utilities",
        permalink: "security"
      },
      %__MODULE__{
        id: 75,
        name: "Sigils",
        description: "Custom sigil implementations for domain-specific syntax extensions",
        permalink: "sigils"
      },
      %__MODULE__{
        id: 76,
        name: "SMS",
        description: "SMS sending and receiving libraries for text messaging integration",
        permalink: "sms"
      },
      %__MODULE__{
        id: 77,
        name: "State Machines",
        description: "Finite state machine implementations and workflow management",
        permalink: "state-machines"
      },
      %__MODULE__{
        id: 78,
        name: "Static Page Generation",
        description: "Static site generators and JAMstack tools for Elixir",
        permalink: "static-page-generation"
      },
      %__MODULE__{
        id: 79,
        name: "Statistics",
        description: "Statistical analysis and mathematical computation libraries",
        permalink: "statistics"
      },
      %__MODULE__{
        id: 80,
        name: "Templating",
        description: "Template engines and view rendering libraries beyond Phoenix templates",
        permalink: "templating"
      },
      %__MODULE__{
        id: 81,
        name: "Testing",
        description: "Testing frameworks, mocking libraries, and test utilities beyond ExUnit",
        permalink: "testing"
      },
      %__MODULE__{
        id: 82,
        name: "Text and Numbers",
        description: "Text processing, string manipulation, and numeric computation utilities",
        permalink: "text-and-numbers"
      },
      %__MODULE__{
        id: 83,
        name: "Third Party APIs",
        description: "Integration libraries for external APIs and web services",
        permalink: "third-party-apis"
      },
      %__MODULE__{
        id: 84,
        name: "Translations and Internationalizations",
        description: "i18n libraries for multi-language support and localization",
        permalink: "translations-and-internationalizations"
      },
      %__MODULE__{
        id: 85,
        name: "Utilities",
        description: "General-purpose utility libraries and helper functions",
        permalink: "utilities"
      },
      %__MODULE__{
        id: 86,
        name: "Validations",
        description: "Data validation libraries and input sanitization tools",
        permalink: "validations"
      },
      %__MODULE__{
        id: 87,
        name: "Version Control",
        description: "Git integration and version control system utilities",
        permalink: "version-control"
      },
      %__MODULE__{
        id: 88,
        name: "Video",
        description: "Video processing, encoding, and multimedia handling libraries",
        permalink: "video"
      },
      %__MODULE__{
        id: 89,
        name: "WebAssembly",
        description: "WebAssembly integration and WASM-related tools for Elixir",
        permalink: "webassembly"
      },
      %__MODULE__{
        id: 90,
        name: "XML",
        description: "XML parsing, generation, and manipulation libraries",
        permalink: "xml"
      },
      %__MODULE__{
        id: 91,
        name: "YAML",
        description:
          "YAML parsing and generation libraries for configuration and data serialization",
        permalink: "yaml"
      }
    ]
  end
end
