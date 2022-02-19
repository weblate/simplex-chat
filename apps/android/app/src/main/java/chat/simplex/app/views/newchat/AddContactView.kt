package chat.simplex.app.views.newchat

import android.content.Context
import android.content.Intent
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.material.Button
import androidx.compose.material.MaterialTheme
import androidx.compose.material.Surface
import androidx.compose.material.Text
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.Share
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.dp
import androidx.navigation.NavController
import chat.simplex.app.Pages
import chat.simplex.app.model.ChatModel
import chat.simplex.app.ui.theme.SimpleButton
import chat.simplex.app.ui.theme.SimpleXTheme
import chat.simplex.app.views.helpers.CloseSheetBar

@Composable
fun AddContactView(chatModel: ChatModel, nav: NavController) {
  val connReq = chatModel.connReqInvitation
  if (connReq != null) {
    val cxt = LocalContext.current
    AddContactLayout(
      connReq = connReq,
      close = { nav.popBackStack() },
      share = { shareText(cxt, connReq) }
    )
  }
}

@Composable
fun AddContactLayout(connReq: String, close: () -> Unit, share: () -> Unit) {
  Column(
    modifier = Modifier
      .padding(horizontal = 8.dp)
      .fillMaxSize()
      .background(MaterialTheme.colors.background),
    horizontalAlignment = Alignment.CenterHorizontally
  ) {
    CloseSheetBar(close)
    Text(
      "Add contact",
      style = MaterialTheme.typography.h1,
      modifier = Modifier.padding(bottom = 8.dp)
    )
    Text(
      "Show QR code to your contact\nto scan from the app",
      style = MaterialTheme.typography.h2,
      textAlign = TextAlign.Center
    )
    QRCode(connReq)
    Text(
      "If you can't show QR code, you can share the invitation link via any channel.\nIt does not have to be secure or private, you just have to know who you are sharing it with.",
      textAlign = TextAlign.Center,
      style = MaterialTheme.typography.caption,
      modifier = Modifier.padding(bottom = 16.dp).padding(horizontal = 16.dp)
    )
    SimpleButton("Share invitation link", icon = Icons.Outlined.Share, click = share)
  }
}

fun shareText(cxt: Context, text: String) {
  val sendIntent: Intent = Intent().apply {
    action = Intent.ACTION_SEND
    putExtra(Intent.EXTRA_TEXT, text)
    type = "text/plain"
  }
  val shareIntent = Intent.createChooser(sendIntent, null)
  cxt.startActivity(shareIntent)
}

@Preview
@Composable
fun PreviewAddContactView() {
  SimpleXTheme {
    AddContactLayout(
      connReq = "https://simplex.chat/contact#/?v=1&smp=smp%3A%2F%2FPQUV2eL0t7OStZOoAsPEV2QYWt4-xilbakvGUGOItUo%3D%40smp6.simplex.im%2FK1rslx-m5bpXVIdMZg9NLUZ_8JBm8xTt%23MCowBQYDK2VuAyEALDeVe-sG8mRY22LsXlPgiwTNs9dbiLrNuA7f3ZMAJ2w%3D",
      close = {},
      share = {}
    )
  }
}