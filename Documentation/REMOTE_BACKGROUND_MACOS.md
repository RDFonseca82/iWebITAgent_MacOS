# Background remoto no macOS

O agente de menu consulta o endpoint já existente a cada 15 segundos, depois de o dispositivo estar registado:

`GET https://agent.iwebit.app/scripts/script_api.php?UniqueID=<UniqueID>`

O JSON pode incluir os campos opcionais:

```json
{
  "SetBackground": 1,
  "BackgroundImage": "https://agent.iwebit.app/backgrounds/empresa.jpg"
}
```

- `SetBackground = 1`: valida, descarrega e aplica a imagem em todos os monitores da sessão do utilizador.
- `SetBackground = 0` ou campo ausente: deixa de impor o background. O fundo que já está aplicado não é removido.
- `BackgroundImage`: aceita um URL HTTPS completo ou um caminho relativo, como `/backgrounds/empresa.jpg`.

A imagem é aplicada com preenchimento proporcional e recorte central, sem deformação. O download está limitado a 10 MB; HTTP, redirecionamentos finais para HTTP, SVG, formatos inválidos, dimensões acima de 16 384 píxeis ou mais de 67 108 864 píxeis no total são rejeitados.

O URL aplicado fica guardado localmente. Enquanto `SetBackground` continuar em `1`, o agente não volta a descarregar o mesmo URL e repõe a imagem local se o utilizador mudar manualmente o fundo. Para publicar conteúdo novo no mesmo caminho, altere o URL, por exemplo:

`https://agent.iwebit.app/backgrounds/empresa.jpg?v=2`

São suportados JPEG, PNG, TIFF e HEIC/HEIF. O resultado ou erro fica registado no log do agente. A alteração é feita pelo agente de menu da sessão do utilizador; o serviço de sistema não tenta alterar o ambiente gráfico.
