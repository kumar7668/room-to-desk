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

##################
This implementation provides:

A reusable email service (email_service.py) to send emails.
A Django management command (send_emails.py) to run batch processing.
A DRF API endpoint (SendBatchEmailView) to trigger batch emails manually.
You can run the management command using:

sh
Copy
Edit
python manage.py send_emails


