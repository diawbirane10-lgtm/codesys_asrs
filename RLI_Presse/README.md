# ASRS Quadra 10 - Banc RLI presse

Banc de mise en service virtuelle dans CODESYS. L'image d'E/S reproduit le contrat cyclique ma�tre-station. Les adresses sont p�dagogiques et ne sont pas associ�es � des E/S physiques.

| Octet | Sortie ma�tre (exemple) | Entr�e ma�tre (exemple) |
|---|---|---|
| 0 | %QB0 bit 0, demande d'arr�t | %IB0 bit 0, r�ponse valide. Bit 1, arr�t confirm� |
| 1 | %QB1 r�serv� | %IB1 compteur de vie |
| 2 | %QB2 ID de demande, poids faible | %IB2 ID de r�ponse, poids faible |
| 3 | %QB3 ID de demande, poids fort | %IB3 ID de r�ponse, poids fort |

Le ma�tre attend une r�ponse corr�l�e et une image fra�che. Le watchdog de liaison et le d�lai de r�alisation de la commande d�clenchent des diagnostics distincts. Apr�s un d�faut, la station doit revenir, l'op�rateur doit acquitter et une nouvelle demande est n�cessaire. Le signal TransferAllowed est la r�ceptivit� du banc, � raccorder ensuite � G3 apr�s validation du contrat complet. La r�ponse simul�e conserv�e ne repr�sente qu'une transaction pr�c�dente. Un d�ploiement r�el exige de d�finir l'�poque de session et le traitement du red�marrage et du rollover.

Le banc applique la mise en service virtuelle et le diagnostic contextualis�. En vue d'une future migration PROFINET, conserver le contrat applicatif et remplacer son adaptateur de transport. Pour une supervision future, exposer les diagnostics avec OPC UA en lecture, hors boucle de commande.

Essais � ex�cuter dans CODESYS : confirmation nominale, r�ponse ancienne, �ch�ance de commande avec station pr�sente, perte de station et retour sans reprise automatique, disparition de la confirmation apr�s autorisation.

## Exécution et résultats

Ouvrir `ASRS_RLI_Presse.project` dans CODESYS V3.5 SP22 Patch 4. Activer En ligne → Simulation, se connecter, charger l’application simulée et démarrer. Ouvrir `VISU_RLI_PRESSE`. Les essais automatiques démarrent avec l’application. Résultat observé le 13 novembre 2026 : tests terminés = 1, tests réussis = 1, premier échec = 0. Les boutons Demander et Libérer ont également été vérifiés en ligne.

Le projet est un banc autonome pour le premier échange presse. Le raccordement à G3 et la validation sur Control Win x64 ou sur un bus physique restent à faire.
