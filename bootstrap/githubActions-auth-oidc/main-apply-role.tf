

data "aws_iam_policy_document" "github_actions_assume_apply_role" {
  statement {
    sid     = "AllowGitHubActionsOidcAssumeRole"
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [data.aws_iam_openid_connect_provider.github_actions.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values   = var.allowed_refs_apply
    }
  }
}

resource "aws_iam_role" "github_actions_deploy_apply" {
  name                 = var.role_name_apply
  description          = "Role assumed by GitHub Actions via OIDC for Terraform deployments."
  assume_role_policy   = data.aws_iam_policy_document.github_actions_assume_apply_role.json
  max_session_duration = var.max_session_duration
}

resource "aws_iam_role_policy_attachment" "github_actions_deploy_apply" {
  role       = aws_iam_role.github_actions_deploy_apply.name
  policy_arn = var.managed_policy_arn_apply
}

