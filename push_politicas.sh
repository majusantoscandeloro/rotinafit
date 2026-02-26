#!/bin/bash
set -e
cd /Users/majusantos/rotinafit
REPO=_repo_privacidade
if [ ! -d "$REPO" ]; then
  git clone https://github.com/majusantoscandeloro/politcasprivacidade.git "$REPO"
fi
cp politicasprivacidade/index.html "$REPO/"
cd "$REPO"
git add index.html
git status
if git diff --cached --quiet; then
  echo "Nenhuma alteração para enviar."
else
  git commit -m "Contato: Thauan Silveira (e-mail e telefone)"
  git push origin main
  echo "Push concluído."
fi
cd ..
rm -rf "$REPO"
