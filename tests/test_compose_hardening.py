"""Assert the hardening flags are actually in the compose file, not just in the docs."""
import re
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
COMPOSE = (ROOT / "docker-compose.yml").read_text()
NGINX = (ROOT / "docker" / "nginx" / "nginx.conf").read_text()
PHP = (ROOT / "docker" / "php" / "php.ini").read_text()
REDIS = (ROOT / "docker" / "redis" / "redis.conf").read_text()


class ComposeHardeningTests(unittest.TestCase):
    def test_no_latest_tags(self):
        self.assertIsNone(re.search(r"image:.*:latest", COMPOSE))

    def test_no_new_privileges_everywhere(self):
        self.assertEqual(COMPOSE.count("no-new-privileges:true"), 4)

    def test_cap_drop_all_present(self):
        self.assertGreaterEqual(COMPOSE.count("cap_drop: [ALL]"), 3)

    def test_internal_back_network(self):
        self.assertIn("internal: true", COMPOSE)

    def test_server_tokens_off(self):
        self.assertIn("server_tokens off;", NGINX)

    def test_php_hardening(self):
        for needle in ("expose_php = Off", "allow_url_include = Off", "open_basedir"):
            self.assertIn(needle, PHP)

    def test_redis_dangerous_commands_renamed(self):
        self.assertIn('rename-command FLUSHALL ""', REDIS)
        self.assertIn("requirepass", REDIS)


if __name__ == "__main__":
    unittest.main()
