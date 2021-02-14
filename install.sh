#! /usr/bin/zsh

export DEBIAN_FRONTEND=noninteractive
echo "Installing dependencies"
apt-get install apt-utils curl cmake pkg-config libtool libtool-bin unzip gettext -y > /dev/null
cd
git clone --quiet https://github.com/romkatv/gitstatus.git
echo "Symlink .zshrc and .tmux.conf"
ln -s ~/dotfiles/zsh/.zshrc ~/.zshrc
echo "export TERM=screen-256color" >> ~/.zshrc
source ~/.zshrc
ln -s dotfiles/tmux/.tmux.conf ~/.tmux.conf

# INSTALL NEOVIM
echo "Installing neovim from nightly prebuild version"
#git clone --quiet https://github.com/neovim/neovim.git && cd neovim
#apt install gperf luajit luarocks libuv1-dev libluajit-5.1-dev libunibilium-dev libmsgpack-dev libtermkey-dev libvterm-dev libutf8proc-dev > /dev/null
#make CMAKE_BUILD_TYPE=RelWithDebInfo > /dev/null
#make install > /dev/null
wget -q https://github.com/neovim/neovim/releases/download/nightly/nvim.appimage
chmod u+x nvim.appimage && ./nvim.appimage --appimage-extract > /dev/null
mv ~/squashfs-root ~/neovim
rm nvim.appimage
echo "neovim installed -> $HOME/neovim"
echo 'export PATH=~/neovim/usr/bin:$PATH' >> ~/.zshrc
source ~/.zshrc
mkdir -p ~/.config/nvim
ln -s ~/dotfiles/nvim/init.vim ~/.config/nvim/init.vim

# INSTALL VIM PLUG
echo "Installing vim-plug"
sh -c 'curl -sfLo "${XDG_DATA_HOME:-$HOME/.local/share}"/nvim/site/autoload/plug.vim --create-dirs \
       https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'
   
# INSTALL Miniconda
echo "Installing miniconda"
cd && curl -s -O https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh > /dev/null
zsh ~/Miniconda3-latest-Linux-x86_64.sh -b -p $HOME/miniconda > /dev/null
source ~/miniconda/bin/activate
conda init zsh > /dev/null
rm ~/Miniconda3-latest-Linux-x86_64.sh
echo "miniconda installed -> $HOME/miniconda"
 
# INSTALL VIM PLUGIN DEPS
echo "Installing pynvim and jedi (deoplete deps)"
zsh -c "pip install jedi pynvim" > /dev/null
echo "All done, please restart shell and then install nvim plugin yourself by running :PlugInstall in vim"
