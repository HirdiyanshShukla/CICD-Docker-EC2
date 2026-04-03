from django.test import TestCase
from django.urls import reverse

class HomeViewTests(TestCase):
    def test_index_view_status_code(self):
        """Test that the index view returns a 200 OK status."""
        url = reverse('index')
        response = self.client.get(url)
        self.assertEqual(response.status_code, 200)

    def test_index_view_uses_correct_template(self):
        """Test that the index view uses the intended template."""
        url = reverse('index')
        response = self.client.get(url)
        self.assertTemplateUsed(response, 'home/index.html')

    def test_index_view_contains_welcome_text(self):
        """Test that the index view contains the expected text."""
        url = reverse('index')
        response = self.client.get(url)
        self.assertContains(response, "Welcome to Home!")
