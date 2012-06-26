use Mojolicious::Lite;
use Digest::MD5 'md5_hex';
use Encode;
use utf8;

# init
init();

# route
get '/' => sub {
	my $self = shift;
	$self->stash(
		title => 'index',
		raw   => '',
	);
	$self->render;
} => 'form';

get '/:id' => sub {
	my $self = shift;
	my $html = get_html($self->param('id'));
	$self->render_not_found unless ($html);
	$self->render(text => $html);
};

get '/:id/edit' => sub {
	my $self = shift;
	my $raw = get_raw($self->param('id'));
	$self->render_not_found unless ($raw);
	$self->stash(
		title => 'edit',
		raw   => $raw,
	);
	$self->render;
} => 'form';

post '/' => sub {
	my $self = shift;
	my $checksum = create($self->param('input'));
	if ($checksum) {
		$self->redirect_to('/'.$checksum);
	} else {
		$self->render_exception('require input');
	}
};

sub get_raw {
	my $id = shift;
	return unless ($id);
	return _get_content(conf('tmp').'/'.$id);
}

sub get_html {
	my $id = shift;
	return unless ($id);
	return _get_content(conf('tmp').'/'.$id.'.html');
}

sub _get_content {
	my $path = shift;
	return unless(-f $path);
	my $result;
	my $fh;
	open $fh, $path;
	$result = do{ local $/; <$fh> };
	close $fh;
	return $result;
}

sub create {
	my $content = shift;
	return unless($content);
	my $checksum = md5_hex(encode_utf8($content));
	my $path = conf('tmp').'/'.$checksum;
	unless (-f $path) {
		my $fh;
		open $fh, '>', $path;
		print $fh $content;
		close $fh;
		_create_html($content, $path);
		return $checksum;
	}
	return $checksum;
}

sub _create_html {
	my $content = shift;
	my $path    = shift;
	my $html    = $path . '.html';
	system <<"...";
vim -n -c ':let html_use_css = 1' -c ':colorscheme molokai' -c ':TOhtml' -c ':sav! $html' -c ':qa' $path > /dev/null 2> /dev/null
...
	my $file = '';
	my $fh;
	open $fh, $html;
	while (<$fh>) {
		if ($_ =~ /^(pre|body) \{/) {
			$_ =~ s/000000/FFFFFF/;
			$_ =~ s/ffffff/000000/;
		}
		$file .= $_;
	}
	close $fh;
	open $fh, '>', $html;
	print $fh $file;
	close $fh;
}

sub init {
	mkdir(conf('tmp'));
}

sub conf {
	my $id = shift;
	return {
		tmp => app->home->rel_dir('tmp'),
	}->{$id};
}

app->start;

__DATA__

@@ form.html.ep

<!DOCTYPE html>
<html>
  <head>
    <title><%= title %></title>
  </head>
  <body>
    <form action="/" method="post">
      <textarea name="input" cols="100" rows="24"><%= $raw %></textarea><br />
      <input type="submit" />
    </form>
  </body>
</html>

@@ exception.html.ep
Error
