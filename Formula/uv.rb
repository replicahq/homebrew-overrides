class Uv < Formula
  desc "Extremely fast Python package installer and resolver, written in Rust. Pinned at v0.1.31"
  homepage "https://github.com/astral-sh/uv"
  url "https://github.com/astral-sh/uv/archive/refs/tags/0.1.31.tar.gz"
  sha256 "26797aa67030585d9fb00ddc8900ad05e0030f33d5dac2413045301b5c3efeea"
  license any_of: ["Apache-2.0", "MIT"]
  head "https://github.com/astral-sh/uv.git", branch: "main"

  bottle do
    root_url "https://storage.googleapis.com/replica_homebrew_overrides_bottles/uv"
    sha256 cellar: :any,                 arm64_sonoma:   "54894ef37c23d8076ab8b85405b12dcd1f80655e44ff26cd4fac97a07fd0363c"
    sha256 cellar: :any,                 arm64_ventura:  "a214cc7f0dd2e3af1a6229f4517055f7ffe813fa127983d23c1f1a0fac21e39c"
    sha256 cellar: :any,                 arm64_monterey: "ffd9940079de05b9bbef561e8a49011a85e83a2093ccb8c5bd81e3092dc6b1e6"
    sha256 cellar: :any,                 sonoma:         "d09e3109fc8fa43f1021fc7c49a14dc68e930ca74e1c7d28d0d21a73b49f3609"
    sha256 cellar: :any,                 ventura:        "51a03137f3f3e914b1b8b1f458fb95097fdd9b380a1eaabce8d2ff85ad2df261"
    sha256 cellar: :any,                 monterey:       "a88c4c61567b1700f5dd7eec3892b69fc1f0c2f1edb468df02274e2b0a62fb13"
    sha256 cellar: :any_skip_relocation, x86_64_linux:   "8f11860e835703c7937b2e07599923113bd125f3f06d267af05fe1e9070cebcb"
  end

  depends_on "pkg-config" => :build
  depends_on "rust" => :build
  depends_on "libgit2"
  depends_on "openssl@3"

  uses_from_macos "python" => :test

  def install
    ENV["LIBGIT2_NO_VENDOR"] = "1"

    # Ensure that the `openssl` crate picks up the intended library.
    ENV["OPENSSL_DIR"] = Formula["openssl@3"].opt_prefix
    ENV["OPENSSL_NO_VENDOR"] = "1"

    system "cargo", "install", "--no-default-features", *std_cargo_args(path: "crates/uv")
    generate_completions_from_executable(bin/"uv", "generate-shell-completion")
  end

  def check_binary_linkage(binary, library)
    binary.dynamically_linked_libraries.any? do |dll|
      next false unless dll.start_with?(HOMEBREW_PREFIX.to_s)

      File.realpath(dll) == File.realpath(library)
    end
  end

  test do
    (testpath/"requirements.in").write <<~EOS
      requests
    EOS

    compiled = shell_output("#{bin}/uv pip compile -q requirements.in")
    assert_match "This file was autogenerated by uv", compiled
    assert_match "# via requests", compiled

    [
      Formula["libgit2"].opt_lib/shared_library("libgit2"),
      Formula["openssl@3"].opt_lib/shared_library("libssl"),
      Formula["openssl@3"].opt_lib/shared_library("libcrypto"),
    ].each do |library|
      assert check_binary_linkage(bin/"uv", library),
             "No linkage with #{library.basename}! Cargo is likely using a vendored version."
    end
  end
end