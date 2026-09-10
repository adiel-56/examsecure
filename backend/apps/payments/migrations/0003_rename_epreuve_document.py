from django.db import migrations, models
import django.db.models.deletion


class Migration(migrations.Migration):

    dependencies = [
        ('exams', '0002_document_add_couverture'),
        ('payments', '0002_transaction_administrateur_and_more'),
    ]

    operations = [
        migrations.RenameField(
            model_name='transaction',
            old_name='epreuve',
            new_name='document',
        ),
        migrations.AlterField(
            model_name='transaction',
            name='document',
            field=models.ForeignKey(db_column='epreuve_id', on_delete=django.db.models.deletion.CASCADE, related_name='transactions', to='exams.document'),
        ),
        migrations.AlterModelOptions(
            name='transaction',
            options={'ordering': ['-created_at'], 'verbose_name': 'Transaction', 'verbose_name_plural': 'Transactions'},
        ),
        migrations.AlterField(
            model_name='paymentconfig',
            name='instructions',
            field=models.TextField(default="Pour accéder à ce document, veuillez envoyer le montant indiqué au numéro Mobile Money de l'administration. Après le paiement, revenez dans l'application et envoyez votre reçu (capture d'écran ou PDF) pour vérification.", help_text="Consignes affichées à l'étudiant avant le paiement"),
        ),
    ]
