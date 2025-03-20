# with celery



# email_service.py
from django.core.mail import send_mail
from django.conf import settings

def send_batch_email(subject, message, recipient_list):
    try:
        send_mail(
            subject,
            message,
            settings.DEFAULT_FROM_EMAIL,
            recipient_list,
            fail_silently=False,
        )
    except Exception as e:
        print(f"Error sending email: {e}")

# tasks.py (Celery Task for Bulk Email)
from celery import shared_task
from myapp.email_service import send_batch_email
from myapp.models import Nominee

@shared_task
def send_bulk_emails():
    pending_nominees = Nominee.objects.filter(notified=False)[:100]
    recipient_list = [nominee.email for nominee in pending_nominees]

    if recipient_list:
        send_batch_email("Training Invitation", "You are invited to the training session.", recipient_list)
        Nominee.objects.filter(email__in=recipient_list).update(notified=True)

# management/commands/send_emails.py
from django.core.management.base import BaseCommand
from myapp.models import Nominee
from myapp.email_service import send_batch_email

class Command(BaseCommand):
    help = 'Send batch emails to nominees'

    def handle(self, *args, **kwargs):
        pending_nominees = Nominee.objects.filter(notified=False)
        batch_size = 100
        
        for i in range(0, len(pending_nominees), batch_size):
            batch = pending_nominees[i:i+batch_size]
            recipient_list = [nominee.email for nominee in batch]
            
            subject = "Training Invitation - Batch Processing"
            message = "You are invited to the training session."
            
            send_batch_email(subject, message, recipient_list)
            batch.update(notified=True)

        self.stdout.write(self.style.SUCCESS('Successfully sent batch emails'))

# views.py
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status
from myapp.models import Nominee
from myapp.email_service import send_batch_email

class SendBatchEmailView(APIView):
    def post(self, request):
        pending_nominees = Nominee.objects.filter(notified=False)
        batch_size = 100
        
        for i in range(0, len(pending_nominees), batch_size):
            batch = pending_nominees[i:i+batch_size]
            recipient_list = [nominee.email for nominee in batch]
            
            subject = "Training Invitation - Batch Processing"
            message = "You are invited to the training session."
            
            send_batch_email(subject, message, recipient_list)
            batch.update(notified=True)
        
        return Response({'message': 'Batch emails sent successfully'}, status=status.HTTP_200_OK)

# celery.py (Celery Configuration in Django)
from celery import Celery
import os

os.environ.setdefault("DJANGO_SETTINGS_MODULE", "myproject.settings")
app = Celery("myproject", broker="pyamqp://guest@localhost//")
app.config_from_object("django.conf:settings", namespace="CELERY")
app.autodiscover_tasks()

# Running Celery Worker
# Open a terminal and run:
# celery -A myproject worker --loglevel=info

# To manually trigger the task in Django Shell:
# from myapp.tasks import send_bulk_emails
# send_bulk_emails.delay()

# Using Windows Task Scheduler as an Alternative
# 1. Create a batch script (send_emails.bat)
# 2. Schedule it in Windows Task Scheduler to run periodically

# Now your project supports bulk email sending via Celery and an API endpoint.
